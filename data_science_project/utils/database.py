import duckdb
from pathlib import Path

class Database:
    def __init__(self, db_path=None):
        """Initialize a DuckDB database connection.
        
        Args:
            db_path: Path to database file or None for in-memory database
        """
        self.db_path = db_path
        self.conn = duckdb.connect(db_path if db_path else ":memory:")
        
    def execute(self, query, params=None):
        """Execute a SQL query.
        
        Args:
            query: SQL query string
            params: Optional parameters for the query
            
        Returns:
            DuckDB result object
        """
        return self.conn.execute(query, params if params else [])
    
    def query_df(self, query, params=None):
        """Execute a SQL query and return results as DataFrame.
        
        Args:
            query: SQL query string
            params: Optional parameters for the query
            
        Returns:
            pandas DataFrame with query results
        """
        return self.execute(query, params).fetchdf()
