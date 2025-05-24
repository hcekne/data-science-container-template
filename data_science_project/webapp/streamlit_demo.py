import streamlit as st
import pandas as pd
import numpy as np
import plotly.express as px
import time

# Set page configuration
st.set_page_config(
    page_title="Data Science Template Demo",
    page_icon="📊",
    layout="wide"
)

# Header
st.title("Data Science Environment Test")
st.markdown("### 🎉 Congratulations! Your data science environment is working!")

# Create tabs for different demos
tab1, tab2, tab3 = st.tabs(["Data Visualization", "Interactive Widgets", "DuckDB Demo"])

with tab1:
    st.header("Data Visualization Demo")
    
    # Generate sample data
    @st.cache_data
    def generate_data():
        dates = pd.date_range('20230101', periods=100)
        df = pd.DataFrame({
            'date': dates,
            'value': np.random.randn(100).cumsum(),
            'category': np.random.choice(['A', 'B', 'C'], 100)
        })
        return df
    
    df = generate_data()
    
    # Display the dataframe
    st.subheader("Sample DataFrame")
    st.dataframe(df.head(10), use_container_width=True)
    
    # Create a Plotly chart
    st.subheader("Interactive Plotly Chart")
    fig = px.line(df, x='date', y='value', color='category', 
                  title='Sample Time Series')
    st.plotly_chart(fig, use_container_width=True)
    
    # Create another chart type
    st.subheader("Distribution by Category")
    hist_fig = px.histogram(df, x='value', color='category', 
                           marginal='box', opacity=0.7,
                           title='Value Distribution by Category')
    st.plotly_chart(hist_fig, use_container_width=True)

with tab2:
    st.header("Interactive Widgets Demo")
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("Basic Inputs")
        
        name = st.text_input("Enter your name", "Data Scientist")
        st.write(f"Hello, {name}!")
        
        age = st.slider("Select your age", 18, 100, 30)
        st.write(f"You selected: {age} years old")
        
        date = st.date_input("Select a date")
        st.write(f"Date: {date}")
        
        uploaded_file = st.file_uploader("Choose a CSV file", type="csv")
        if uploaded_file is not None:
            data = pd.read_csv(uploaded_file)
            st.write("Preview of uploaded data:")
            st.dataframe(data.head())
    
    with col2:
        st.subheader("Advanced Widgets")
        
        progress_demo = st.checkbox("Show progress bar demo")
        if progress_demo:
            progress_bar = st.progress(0)
            for i in range(100):
                time.sleep(0.01)
                progress_bar.progress(i + 1)
            st.success("Completed!")
        
        tab_choice = st.radio(
            "Select visualization type",
            ["Line Chart", "Bar Chart", "Scatter Plot"]
        )
        
        # Create sample data for the selected visualization
        chart_data = pd.DataFrame(
            np.random.randn(20, 3),
            columns=['A', 'B', 'C']
        )
        
        if tab_choice == "Line Chart":
            st.line_chart(chart_data)
        elif tab_choice == "Bar Chart":
            st.bar_chart(chart_data)
        else:
            st.scatter_chart(
                chart_data, 
                x='A', 
                y='B', 
                size='C', 
                color=chart_data['C']
            )

with tab3:
    st.header("DuckDB Demo")
    
    try:
        import duckdb
        
        st.success("DuckDB is installed and working!")
        
        # Create sample data
        st.subheader("Running SQL queries with DuckDB")
        
        code = '''
        # Connect to in-memory DuckDB
        conn = duckdb.connect(":memory:")
        
        # Create sample data with Pandas then register it with DuckDB
        import pandas as pd
        import numpy as np
        
        # Create a sample dataframe
        df = pd.DataFrame({
            'id': range(1, 1001),
            'value': np.random.rand(1000) * 100,
            'category': np.random.choice(['Low', 'Medium', 'High'], size=1000, 
                                        p=[0.3, 0.4, 0.3])
        })
        
        # Register the dataframe with DuckDB
        conn.register('sample_data', df)
        
        # Run a SQL query
        result = conn.execute("""
            SELECT 
                category,
                COUNT(*) as count,
                AVG(value) as avg_value,
                MIN(value) as min_value,
                MAX(value) as max_value
            FROM sample_data
            GROUP BY category
            ORDER BY avg_value DESC
        """).fetchdf()
        '''
        
        st.code(code, language='python')
        
        # Actually run the code
        conn = duckdb.connect(":memory:")
        
        # Create sample data with Pandas
        df = pd.DataFrame({
            'id': range(1, 1001),
            'value': np.random.rand(1000) * 100,
            'category': np.random.choice(['Low', 'Medium', 'High'], size=1000, 
                                        p=[0.3, 0.4, 0.3])
        })
        
        # Register the dataframe with DuckDB
        conn.register('sample_data', df)
        
        # Run a SQL query
        result = conn.execute("""
            SELECT 
                category,
                COUNT(*) as count,
                AVG(value) as avg_value,
                MIN(value) as min_value,
                MAX(value) as max_value
            FROM sample_data
            GROUP BY category
            ORDER BY avg_value DESC
        """).fetchdf()
        
        # Display the results
        st.dataframe(result, use_container_width=True)
        
        # Create a visualization
        fig = px.bar(result, x='category', y='count', 
                    color='avg_value', 
                    text='count',
                    title='Category Distribution with Average Values',
                    color_continuous_scale='Viridis')
        st.plotly_chart(fig, use_container_width=True)
        
        # Show more advanced DuckDB query
        st.subheader("Advanced SQL Query Example")
        advanced_query = conn.execute("""
            SELECT 
                category,
                ROUND(value) AS rounded_value,
                COUNT(*) AS frequency
            FROM sample_data
            GROUP BY category, rounded_value
            ORDER BY category, frequency DESC
            LIMIT 15
        """).fetchdf()
        
        st.dataframe(advanced_query, use_container_width=True)
        
    except ImportError:
        st.error("DuckDB is not installed. Please install it with: pip install duckdb")
    except Exception as e:
        st.error(f"DuckDB error: {str(e)}")

        # Footer
st.markdown("---")
st.markdown("### Data Science Container Template")
st.markdown(
    "This demo shows that your environment is correctly set up with Streamlit, "
    "Pandas, NumPy, Plotly, and DuckDB. You're ready to start your data science project!"
)