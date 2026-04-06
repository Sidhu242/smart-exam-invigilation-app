import os, json, sys
import psycopg2
url = os.getenv('DATABASE_URL')
if not url:
    print('DATABASE_URL not set')
    sys.exit(1)
conn = psycopg2.connect(url)
cur = conn.cursor()
cur.execute("SELECT column_name FROM information_schema.columns WHERE table_name='users'")
cols = [row[0] for row in cur.fetchall()]
print(json.dumps(cols))
conn.close()
