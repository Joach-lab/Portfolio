
import streamlit as st
import pandas as pd
import numpy as np

# Read in the data
data_URL ="C:/Users/Euro/Downloads/Business financial data.csv"

# Describe the web dashboard
st.title(" Quick preview of data")
st.markdown("This shows a quick preview of a financial data sample using Steamlit")

data = pd.read_csv(data_URL,nrows=10)
st.subheader("Dataframe")
st.data_editor(data)

st.subheader("Line plot and bar plots for selected columns")
columns_plot = st.multiselect('Select Columns to Plot', data.columns)
selected_df = data[columns_plot]
a,b =st.columns(2)
with a:
    st.line_chart(selected_df)
with b:
    st.bar_chart(selected_df)