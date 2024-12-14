import psycopg2
import os

# Environment variables for database connection
# DB_URL = os.environ.get('AWS_RDS_URL')
# DB_PORT = os.environ.get('AWS_RDS_PORT')
# DB_USER = os.environ.get('AWS_RDS_USERNAME')
# DB_PASSWORD = os.environ.get('AWS_RDS_PASSWORD')
# DB_NAME = os.environ.get('AWS_RDS_DB_NAME')


db_host = 'microservice.caywlfxrbtml.eu-central-1.rds.amazonaws.com'
db_port = '5432'
db_user = 'postgres'
db_password = '8nDzLEzeyBXqyODaJa3j'
db_name = 'microservice'
table_name = 'users'

# Connect to the database
conn = psycopg2.connect(
    host=db_host,
    dbname=db_name,
    user=db_user,
    password=db_password,
    port=db_port
)
cur = conn.cursor()

# Create table
cur.execute('''
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(100) NOT NULL
)
''')

# Insert dummy data
dummy_users = [
    ('Alice_dummy', 'alice_dummy@example.com', 'password123_dummy'),
    ('Bob_dummy', 'bob_dummy@example.com', 'password456_dummy'),
    ('Charlie_dummy', 'charlie_dummy@example.com', 'password789_dummy')
]

for user in dummy_users:
    cur.execute('''
    INSERT INTO users (name, email, password) VALUES (%s, %s, %s)
    ''', user)

conn.commit()

# Close the connection
cur.close()
conn.close()