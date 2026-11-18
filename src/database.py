
import os
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

# Project root
BASE_DIR = Path(__file__).resolve().parent.parent

# Load credentials
load_dotenv(BASE_DIR / ".env")

password = os.getenv("DB_PASSWORD")

if not password:
    raise ValueError(
        "DB_PASSWORD is missing. Check your .env file."
    )

# Build connection URL safely
database_url = URL.create(
    drivername="postgresql+psycopg",
    username=os.getenv("DB_USER", "postgres"),
    password=password,
    host=os.getenv("DB_HOST", "localhost"),
    port=int(os.getenv("DB_PORT", "5432")),
    database=os.getenv("DB_NAME", "commerceiq"),
)

# Create engine
engine = create_engine(
    database_url,
    pool_pre_ping=True,
    connect_args={"connect_timeout": 10}
)


def test_connection():

    try:
        with engine.connect() as connection:

            result = connection.execute(
                text("""
                    SELECT
                        current_database(),
                        current_user,
                        version();
                """)
            )

            database, user, version = result.fetchone()

            print("\nPOSTGRESQL CONNECTION SUCCESSFUL")
            print("-" * 55)
            print("Database:", database)
            print("User:", user)
            print("Version:", version)

            return True

    except Exception as error:
        print("\nDATABASE CONNECTION FAILED")
        print("Error:", error)
        return False

    finally:
        engine.dispose()


if __name__ == "__main__":
    test_connection()
