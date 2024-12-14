from flask import Flask, request, redirect, url_for, render_template
import psycopg2
import logging

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.DEBUG)

# RDS database configuration
db_host = 'microservice.caywlfxrbtml.eu-central-1.rds.amazonaws.com'
db_port = '5432'
db_user = 'postgres'
db_password = '8nDzLEzeyBXqyODaJa3j'
db_name = 'microservice'
table_name = 'users'

# Database Connection
def get_db_connection():
    try:
        conn = psycopg2.connect(
            dbname=db_name, 
            user=db_user, 
            password=db_password, 
            host=db_host
        )
        logging.debug("Database connection successful.")
        return conn
    except Exception as e:
        logging.debug(f"Database connection failed: {e}")
        return None

# Routes
@app.route('/')
def login():
    return render_template('login.html')

@app.route('/login', methods=['POST'])
def login_post():
    email = request.form['email']
    password = request.form['password']

    conn = get_db_connection()
    if conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users WHERE email = %s AND password = %s", (email, password))
        user = cursor.fetchone()
        cursor.close()
        conn.close()

        if user:
            return redirect(url_for('product'))
    
    return redirect(url_for('login'))

@app.route('/product')
def product():
    return redirect("http://crypto-app-882103207.eu-central-1.elb.amazonaws.com:5000/welcomepage")
    #return "Hello, this is the product page."

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
