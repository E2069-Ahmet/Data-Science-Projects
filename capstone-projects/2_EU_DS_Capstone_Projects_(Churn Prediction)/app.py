import pickle
import pandas as pd
import numpy as np
import streamlit as st
from sklearn.preprocessing import scale, StandardScaler

df = pd.read_csv("HR_Dataset.csv")
features = pickle.load(open("features.pkl", "rb"))
model = pickle.load(open("rf_tuned_model.pkl", "rb"))
#X = pickle.load(open("X", "rb"))
#model2 = pickle.load(open("xgb_model", "rb"))

#st.write(df.head())
#st.table(df.head())
#st.dataframe(df.head())


# st.sidebar.title("Churn Probability of a single Customer")
html_temp = """
<div style="background-color:tomato;padding:1.5px">
<h1 style="color:white;text-align:center;">Churn Prediction ML app </h1>
</div><br>"""
st.markdown(html_temp,unsafe_allow_html=True)

satisfaction_level=st.slider("Employee satisfaction point", 0.01, 1.00, 0.30, step=0.01)
last_evaluation=st.slider("Evaluated performance by the employer", 0.01, 1.00, 0.30, step=0.01)
number_project=st.slider("How many of projects assigned to an employee?", 2 ,7, 4, step=1)
average_montly_hours=st.slider("How many hours in averega an employee worked in a month?", 96, 310, 200, step=1)
time_spend_company=st.selectbox("The number of years spent by an employee in the company", (2, 3, 4, 5, 6, 7, 8, 9, 10))
#work_accident=st.selectbox("Whether an employee has had a work accident or not", ("Yes", 'No'))
#promotion_last_5years=st.selectbox("Whether an employee has had a promotion in the last 5 years or not", ('Yes', 'No'))
#salary= st.selectbox("Salary level of the employee", ('low', 'medium', 'high'))
#departments = st.selectbox("Employee's working department/division", ('IT', 'RandD', 'accounting', 'hr', 'management', 'marketing', 'product_mng', 'sales', 'support', 'technical'))




def single_customer():
    my_dict = {"satisfaction_level" :satisfaction_level,
        "last_evaluation":last_evaluation,
        "number_project": number_project,
        "average_montly_hours": average_montly_hours,
        "time_spend_company": time_spend_company}
        #"work_accident": work_accident,
        #"promotion_last_5years":promotion_last_5years,
        #"salary": salary,
        #"departments": departments}
    
    #for i in my_dict:
     #   if i == "salary" and my_dict[i] == "low":
      #      my_dict[i] = 0
       # elif i == "salary" and my_dict[i] == "medium":
        #    my_dict[i] = 1
        #elif i == "salary" and my_dict[i] == "high":
         #   my_dict[i] = 2
        #elif i == "work_accident" and my_dict[i] == "Yes":
            #my_dict[i] = 1
        #elif i == "work_accident" and my_dict[i] == "No":
            #my_dict[i] = 0
        #elif i == "promotion_last_5years" and my_dict[i] == "Yes":
            #my_dict[i] = 1
        #elif i == "promotion_last_5years" and my_dict[i] == "No":
            #my_dict[i] = 0
        #else:
            #continue}
   
    df_sample = pd.DataFrame.from_dict([my_dict])
    df_sample = pd.get_dummies(df_sample).reindex(columns=features, fill_value=0)
    return df_sample


df2 = single_customer()
proba = model.predict(df2)

if st.button("Submit"):
    if proba == 1:
        st.error("Churn")
    else:
        st.success("Not Churn")
    
    #st.sidebar.success(f"The churn probability of selected customer is % {proba[:,1][0]*100:.2f}")



