INSERT INTO hotel (name, location, metadata)
    VALUES ('The Bull Inn, Sonning', st_geographyfromtext('POINT(-0.9117785 51.4736977)'),  
                '{"bed_types": ["Standard Double", "Deluxe Double", "Superior King"], "board_type": "Breakfast included", 
                "city": "Reading", "country": "UK", "free_cancellation": false, "gym": false, "official_rating": 3,
                "number_of_reviews": 536, "parking": "Free", "price_per_night": 156, "review_score": 8.6, 
                "room_facilities": ["Hairdryer", "Flat-screen TV", "Free toiletries", "Wi-Fi", "Electric kettle"], 
                "hotel_facilities": ["Restaurant", "Bar", "Garden", "Pets allowed", "Non-smoking"]}'
            );

INSERT INTO hotel (name, location, metadata)
           ('De L’Europe Amsterdam', st_geographyfromtext('POINT(4.8942865 52.3675112)'),  
                '{"bed_types": ["Junior Suite", "Media Nanny Music Suite", "Van Gogh Museum Suite", "Salle Privée Suite"], "official_rating": 5,
                "board_type": "Continental Breakfast included", "city": "Amsterdam", "country": "Netherlands",  
                "number_of_reviews": 325, "review_score": 9.3, "parking": "Paid", "price_per_night": 2450,  
                "room_facilities": ["Hairdryer", "TV", "Free toiletries", "Wi-Fi", "Room Service"], 
                "hotel_facilities": ["Indoor swimming pool", "Spa and wellness centre", "Fitness centre", 
                                        "Barber/beauty shop", "Soundproof rooms", "5 restaurants"]}'
            );

INSERT INTO hotel (name, location, metadata)
           ('Dromoland Castle Limerick', st_geographyfromtext('POINT(-8.6581638 52.6517643)'),  
                '{"bed_types": ["Deluxe Double", "Stateroom Twin"], "official_rating": 5,
                "board_type": "Breakfast included", "city": "Limerick", "country": "Ireland",  
                "number_of_reviews": 147, "review_score": 9.4, "parking": "Free", "price_per_night": 5450,  
                "room_facilities": ["Hairdryer", "TV", "Free toiletries", "Wi-Fi", "Room Service", "Bathrobe"], 
                "hotel_facilities": ["Indoor swimming pool", "Spa and wellness centre", "Fitness centre", 
                                        "Tennis Court", "Fishing", "Cycling", "2 restaurants"]}'
            );







