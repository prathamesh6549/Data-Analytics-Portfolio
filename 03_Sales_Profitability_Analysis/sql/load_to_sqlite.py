"""
Load the raw CSV into a SQLite database so the SQL queries can be run.

Usage:  python sql/load_to_sqlite.py
Output: sql/superstore.db  (table: orders)
"""
import sqlite3

import pandas as pd

df = pd.read_csv('data/superstore_sales.csv')

# snake_case column names are easier to use in SQL
df.columns = (df.columns.str.strip().str.lower()
              .str.replace(' ', '_').str.replace('-', '_'))

# Store dates in ISO format (YYYY-MM-DD) so SQLite date functions work
for col in ['order_date', 'ship_date']:
    df[col] = pd.to_datetime(df[col], format='%m/%d/%Y').dt.strftime('%Y-%m-%d')

with sqlite3.connect('sql/superstore.db') as con:
    df.to_sql('orders', con, if_exists='replace', index=False)
    print('Loaded', len(df), 'rows into sql/superstore.db -> table "orders"')
    print('Columns:', ', '.join(df.columns))
