"""
Data Platform Dashboard - Streamlit Sample App
"""

import os
import streamlit as st
import pandas as pd
import numpy as np
import plotly.express as px

st.set_page_config(
    page_title="Data Platform Dashboard",
    page_icon="📊",
    layout="wide"
)

# 環境変数
STORAGE_NODE_IP = os.environ.get('STORAGE_NODE_IP', '10.10.10.10')
DWH_NODE_IP = os.environ.get('DWH_NODE_IP', '10.10.10.20')


@st.cache_data
def generate_sample_data():
    np.random.seed(42)
    dates = pd.date_range(start='2024-01-01', periods=100, freq='D')
    return pd.DataFrame({
        'date': dates,
        'sales': np.random.randint(100, 1000, 100),
        'visitors': np.random.randint(500, 5000, 100),
        'region': np.random.choice(['東京', '大阪', '名古屋', '福岡'], 100)
    })


# サイドバー
st.sidebar.title("🔧 設定")
st.sidebar.info(f"""
**接続情報**
- Storage: {STORAGE_NODE_IP}
- DWH: {DWH_NODE_IP}
""")

# メイン
st.title("📊 Data Platform Dashboard")
st.markdown("---")

df = generate_sample_data()

# KPI
col1, col2, col3 = st.columns(3)
with col1:
    st.metric("総売上", f"¥{df['sales'].sum():,}")
with col2:
    st.metric("総訪問者", f"{df['visitors'].sum():,}")
with col3:
    st.metric("データ件数", f"{len(df):,}")

st.markdown("---")

# グラフ
col1, col2 = st.columns(2)

with col1:
    st.subheader("📈 売上推移")
    fig = px.line(df, x='date', y='sales')
    st.plotly_chart(fig, use_container_width=True)

with col2:
    st.subheader("🥧 地域別売上")
    region_sales = df.groupby('region')['sales'].sum().reset_index()
    fig = px.pie(region_sales, values='sales', names='region')
    st.plotly_chart(fig, use_container_width=True)

# データ
st.subheader("📋 データプレビュー")
st.dataframe(df.head(20), use_container_width=True)
