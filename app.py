"""
Flask web application for Book-It.com hotel semantic search
"""
from flask import Flask, render_template, request, jsonify
import os
import psycopg
from psycopg.rows import dict_row
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)

# Initialize OpenAI client
openai_client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"), base_url="https://infer.dev.takara.ai/v1")

def get_db_connection():
    """Create database connection"""
    conn_string = os.getenv("DATABASE_URL")
    return psycopg.connect(conn_string, row_factory=dict_row)

def generate_query_embedding(query_text):
    """Generate embedding for search query"""
    response = openai_client.embeddings.create(
        model="ds1-fukuro",
        dimensions=512,
        input=query_text
    )
    return response.data[0].embedding

@app.route('/')
def index():
    """Serve the main page"""
    return render_template('index.html')

@app.route('/search', methods=['POST'])
def search():
    """
    Semantic search endpoint for hotels

    Request JSON:
    {
        "query": "Find a luxury hotel with spa near me",
        "latitude": 51.5074,      // optional
        "longitude": -0.1276,     // optional
        "max_distance_km": 10,    // optional, default 10
        "limit": 10               // optional, default 10
    }

    Response JSON:
    {
        "results": [
            {
                "id": "uuid",
                "name": "Hotel name",
                "latitude": 51.5074,
                "longitude": -0.1276,
                "metadata": { ... },
                "distance_km": 2.5,    // only if location provided
                "similarity": 0.89
            }
        ]
    }
    """
    data = request.json
    query = data.get('query', '').strip()
    latitude = data.get('latitude')
    longitude = data.get('longitude')
    max_distance_km = data.get('max_distance_km', 10)
    limit = data.get('limit', 10)

    # Validate input: need either query or location
    if not query and not (latitude and longitude):
        return jsonify({"error": "Please provide either a search query or a location"}), 400

    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # If no query text, do distance-only search
        if not query and latitude and longitude:
            # Distance-based search only (no semantic matching)
            cursor.execute("""
                SELECT
                    id,
                    name,
                    ST_Y(location::geometry) as latitude,
                    ST_X(location::geometry) as longitude,
                    metadata,
                    ST_Distance(location, ST_GeogFromText(%s)) / 1000 as distance_km
                FROM hotel
                WHERE ST_DWithin(location, ST_GeogFromText(%s), %s)
                ORDER BY distance_km
                LIMIT %s
            """, (
                f"POINT({longitude} {latitude})",
                f"POINT({longitude} {latitude})",
                max_distance_km * 1000,  # Convert km to meters
                limit
            ))
        else:
            # Generate embedding for the search query
            query_embedding = generate_query_embedding(query)

            # Build the SQL query with semantic search
            if latitude and longitude:
                # Search with geospatial filter
                cursor.execute("""
                    SELECT
                        id,
                        name,
                        ST_Y(location::geometry) as latitude,
                        ST_X(location::geometry) as longitude,
                        metadata,
                        ST_Distance(location, ST_GeogFromText(%s)) / 1000 as distance_km,
                        1 - (embedding <=> %s::vector) as similarity
                    FROM hotel
                    WHERE ST_DWithin(location, ST_GeogFromText(%s), %s)
                        AND embedding IS NOT NULL
                    ORDER BY embedding <=> %s::vector
                    LIMIT %s
                """, (
                    f"POINT({longitude} {latitude})",
                    str(query_embedding),
                    f"POINT({longitude} {latitude})",
                    max_distance_km * 1000,  # Convert km to meters
                    str(query_embedding),
                    limit
                ))
            else:
                # Search without location filter (semantic only)
                cursor.execute("""
                    SELECT
                        id,
                        name,
                        ST_Y(location::geometry) as latitude,
                        ST_X(location::geometry) as longitude,
                        metadata,
                        1 - (embedding <=> %s::vector) as similarity
                    FROM hotel
                    WHERE embedding IS NOT NULL
                    ORDER BY embedding <=> %s::vector
                    LIMIT %s
                """, (
                    str(query_embedding),
                    str(query_embedding),
                    limit
                ))

        results = cursor.fetchall()

        # Format results
        formatted_results = []
        for row in results:
            result = {
                "id": str(row['id']),
                "name": row['name'],
                "latitude": float(row['latitude']),
                "longitude": float(row['longitude']),
                "metadata": row['metadata']
            }
            if 'similarity' in row:
                result['similarity'] = float(row['similarity'])
            if 'distance_km' in row:
                result['distance_km'] = round(float(row['distance_km']), 2)
            formatted_results.append(result)

        cursor.close()
        conn.close()

        return jsonify({"results": formatted_results})

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, port=5000)
