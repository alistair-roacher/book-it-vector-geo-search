"""
Generate vector embeddings for hotels and update the database
"""
import os
import psycopg
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

def create_embedding_text(name, metadata):
    """Create descriptive text for embedding generation"""
    text_parts = [f"Hotel: {name}"]

    # Official rating
    text_parts.append(f"{metadata['official_rating']} star hotel")

    # Location
    text_parts.append(f"Located in {metadata['city']}")

    # Review quality
    if metadata['number_of_reviews'] > 100:
        text_parts.append(f"Highly reviewed with {metadata['number_of_reviews']} reviews")
    text_parts.append(f"Review score: {metadata['review_score']} out of 10")

    # Amenities
    if metadata.get('swimming_pool'):
        text_parts.append("Swimming pool")
    if metadata.get('gym'):
        text_parts.append("Gym")
    if metadata.get('spa'):
        text_parts.append("Spa")
    if metadata.get('sauna'):
        text_parts.append("Sauna")

    # Parking
    if metadata['parking'] == 'Free':
        text_parts.append("Free parking")
    elif metadata['parking'] == 'Paid':
        text_parts.append("Paid parking available")
    elif metadata['parking'] == 'On Street':
        text_parts.append("On-street parking")

    # Cancellation
    if metadata.get('free_cancellation'):
        text_parts.append("Free cancellation")

    # Board type
    text_parts.append(f"Board type: {metadata['board_type']}")

    # Hotel facilities
    if metadata.get('hotel_facilities'):
        facilities_str = ", ".join(metadata['hotel_facilities'][:10])  # Limit to first 10
        text_parts.append(f"Hotel facilities: {facilities_str}")

    # Room facilities
    if metadata.get('room_facilities'):
        facilities_str = ", ".join(metadata['room_facilities'][:10])  # Limit to first 10
        text_parts.append(f"Room facilities: {facilities_str}")

    # Bed types
    if metadata.get('bed_types'):
        bed_str = ", ".join(metadata['bed_types'])
        text_parts.append(f"Bed types available: {bed_str}")

    # Price indication
    price = metadata.get('price_per_night')
    if price:
        if price < 80:
            text_parts.append("Budget-friendly")
        elif price > 200:
            text_parts.append("Luxury accommodation")
        else:
            text_parts.append("Mid-range pricing")

    return ". ".join(text_parts)

def generate_embeddings():
    """Generate embeddings for all hotels in the database"""
    # Initialize OpenAI client
    openai_api_key = os.getenv("OPENAI_API_KEY")
    if not openai_api_key:
        raise ValueError("OPENAI_API_KEY environment variable not set. Add it to your .env file.")

    client = OpenAI(api_key=openai_api_key, base_url="https://infer.dev.takara.ai/v1")

    # Connect to database
    conn_string = os.getenv("DATABASE_URL")
    if not conn_string:
        raise ValueError("DATABASE_URL environment variable not set. Add it to your .env file.")

    print("Connecting to database...")
    conn = psycopg.connect(conn_string)
    cursor = conn.cursor()

    try:
        # Fetch all hotels without embeddings
        cursor.execute("""
            SELECT id, name, metadata
            FROM hotel
            WHERE embedding IS NULL
        """)

        hotels = cursor.fetchall()
        print(f"Found {len(hotels)} hotels without embeddings")

        if len(hotels) == 0:
            print("All hotels already have embeddings!")
            return

        print("Generating embeddings using Takara-DS1 ...")

        # Generate and update embeddings
        for i, (hotel_id, name, metadata) in enumerate(hotels, 1):
            # Create descriptive text
            text = create_embedding_text(name, metadata)
            print(f"Embedding: {1}", text)

            # Generate embedding using OpenAI
            response = client.embeddings.create(
                model="ds1-fukuro", 
                dimensions=512,
                input=text
            )

            embedding = response.data[0].embedding

            # Update database
            cursor.execute("""
                UPDATE hotel
                SET embedding = %s::vector
                WHERE id = %s
            """, (
                str(embedding),
                hotel_id
            ))

            # Commit every 10 hotels and show progress
            if i % 10 == 0:
                conn.commit()
                print(f"  Processed {i}/{len(hotels)} hotels ({i*100//len(hotels)}%)")

        # Final commit
        conn.commit()
        print(f"\nSuccessfully generated embeddings for {len(hotels)} hotels")

        # Verify completion
        cursor.execute("SELECT COUNT(*) FROM hotel WHERE embedding IS NOT NULL")
        count_with_embeddings = cursor.fetchone()[0]
        print(f"Total hotels with embeddings: {count_with_embeddings}")

    except Exception as e:
        conn.rollback()
        print(f"Error: {e}")
        raise
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    generate_embeddings()
