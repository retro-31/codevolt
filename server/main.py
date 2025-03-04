import uuid
from flask import Flask, request, jsonify
import psycopg2
from psycopg2 import sql # Optional: if score exceeds threshold, save an alert image and try to play the alarm sound.

app = Flask(__name__)

# Database connection parameters – update these with your actual settings
DB_HOST = "localhost"
DB_NAME = "helmate"
DB_USER = "postgres"
DB_PASS = "admin"
DB_PORT = 5432

def get_db_connection():
    """Establish a new database connection."""
    conn = psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASS,
        port=DB_PORT
    )
    return conn

def create_users_table():
    """Create the 'users' table if it does not already exist."""
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS users (
            email_id TEXT PRIMARY KEY,
            password TEXT NOT NULL
        )
    """)
    conn.commit()
    cur.close()
    conn.close()

# Create the users table when the server starts
create_users_table()

@app.route('/register', methods=['POST'])
def register():
    """Register a new user with a hashed password."""
    data = request.get_json()
    if not data or 'email' not in data or 'password' not in data:
        return jsonify({"status": "failure", "message": "Missing email or password"}), 400

    email = data['email']
    password = data['password']

    conn = get_db_connection()
    cur = conn.cursor()

    # Check if the user already exists
    cur.execute("SELECT email_id FROM users WHERE email_id = %s", (email,))
    user = cur.fetchone()
    if user:
        cur.close()
        conn.close()
        return jsonify({"status": "failure", "message": "User already exists"}), 409

    # Insert the new user
    try:
        cur.execute("INSERT INTO users (email_id, password) VALUES (%s, %s)", (email, password))
        conn.commit()
    except Exception as e:
        conn.rollback()
        cur.close()
        conn.close()
        return jsonify({"status": "failure", "message": str(e)}), 500

    cur.close()
    conn.close()
    return jsonify({"status": "success", "message": "User registered successfully"}), 201

@app.route('/login', methods=['POST'])
def login():
    """Authenticate a user and create a session table for session-specific data."""
    data = request.get_json()
    if not data or 'email' not in data or 'password' not in data:
        return jsonify({"status": "failure", "message": "Missing email or password"}), 400

    email = data['email']
    password = data['password']

    conn = get_db_connection()
    cur = conn.cursor()

    # Fetch the stored hashed password for the given email
    cur.execute("SELECT password FROM users WHERE email_id = %s", (email,))
    result = cur.fetchone()

    if not result:
        cur.close()
        conn.close()
        return jsonify({"status": "failure", "message": "User not found"}), 404

    stored_password = result[0]
    if stored_password == password:
        # Generate a unique session id
        session_id = str(uuid.uuid4())
        # Create a valid table name by replacing hyphens with underscores
        table_name = f"session_{session_id.replace('-', '_')}"
        
        # Create a session-specific table to store location, speed, altitude, and angular velocity
        create_table_query = f"""
            CREATE TABLE {table_name} (
        accelerometer_x FLOAT,
        accelerometer_y FLOAT,
        accelerometer_z FLOAT,
        gyroscope_x FLOAT,
        gyroscope_y FLOAT,
        gyroscope_z FLOAT,
        crash_status TEXT,
        timestamp TIMESTAMP NOT NULL
        );

        """
        try:
            cur.execute(create_table_query)
            conn.commit()
        except Exception as e:
            conn.rollback()
            cur.close()
            conn.close()
            return jsonify({"status": "failure", "message": f"Error creating session table: {str(e)}"}), 500
        
        # Create the user_sessions table if it doesn't exist.
        # This table maps each email to its current session_id.
        create_sessions_table_query = """
            CREATE TABLE IF NOT EXISTS user_sessions (
                email_id TEXT PRIMARY KEY,
                session_id TEXT NOT NULL,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """
        try:
            cur.execute(create_sessions_table_query)
            conn.commit()
        except Exception as e:
            conn.rollback()
            cur.close()
            conn.close()
            return jsonify({"status": "failure", "message": f"Error creating user_sessions table: {str(e)}"}), 500

        # Insert or update the session information for the user.
        # If the email already exists, update the session_id and updated_at.
        upsert_query = """
            INSERT INTO user_sessions (email_id, session_id)
            VALUES (%s, %s)
            ON CONFLICT (email_id)
            DO UPDATE SET session_id = EXCLUDED.session_id, updated_at = CURRENT_TIMESTAMP
        """
        try:
            cur.execute(upsert_query, (email, session_id))
            conn.commit()
        except Exception as e:
            conn.rollback()
            cur.close()
            conn.close()
            return jsonify({"status": "failure", "message": f"Error updating user_sessions table: {str(e)}"}), 500

        cur.close()
        conn.close()
        # Return the session id to the client so they can send session data
        return jsonify({
            "status": "success",
            "message": "Login successful",
            "session_id": session_id
        }), 200
    else:
        cur.close()
        conn.close()
        return jsonify({"status": "failure", "message": "Invalid credentials"}), 401



    if score > 15:
        alert_image_path = os.path.join(os.getcwd(), 'alert_image.jpg')
        cv2.imwrite(alert_image_path, frame)
        try:
            if score > 20:
                sound.play()
        except Exception as e:
            print("Error playing sound:", e)


@app.route('/session_data', methods=['POST'])
def session_data():
    """
    Accepts session data and stores it in the session-specific table.
    The request JSON must include a valid session_id.
    """
    data = request.get_json()
    if not data or 'session_id' not in data:
        return jsonify({"status": "failure", "message": "Missing session_id"}), 400

    # Convert the session_id into the table name format used in login
    raw_session_id = data['session_id']
    table_name = f"session_{raw_session_id.replace('-', '_')}"

    # Extract sensor data from the JSON
    accelerometer = data.get('accelerometer', {})
    gyroscope = data.get('gyroscope', {})

    ax = accelerometer.get('x')
    ay = accelerometer.get('y')
    az = accelerometer.get('z')

    gx = gyroscope.get('x')
    gy = gyroscope.get('y')
    gz = gyroscope.get('z')

    crash_status = data.get('crash_status')
    timestamp = data.get('timestamp')  # Expecting ISO8601 string

    # Establish database connection
    conn = get_db_connection()
    cur = conn.cursor()

    # Build the insert query using psycopg2.sql to safely inject the table name.
    insert_query = sql.SQL("""
        INSERT INTO {table} (
            accelerometer_x, accelerometer_y, accelerometer_z,
            gyroscope_x, gyroscope_y, gyroscope_z,
            crash_status, timestamp
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
    """).format(
        table=sql.Identifier(table_name)
    )

    try:
        cur.execute(insert_query, (ax, ay, az, gx, gy, gz, crash_status, timestamp))
        conn.commit()
    except Exception as e:
        conn.rollback()
        cur.close()
        conn.close()
        return jsonify({"status": "failure", "message": f"Error inserting session data: {str(e)}"}), 500

    cur.close()
    conn.close()
    return jsonify({"status": "success", "message": "Session data recorded successfully"}), 200



if __name__ == '__main__':
    # Bind to all interfaces so that the server is accessible on your local network
    app.run(host='0.0.0.0', port=5000, debug=True)
