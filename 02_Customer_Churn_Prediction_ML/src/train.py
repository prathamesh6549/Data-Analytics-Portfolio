"""
Train the churn model from the command line (same steps as the notebook, without the charts).

Usage:  python src/train.py
Output: models/churn_model.joblib
"""
import joblib
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

DATA = 'data/telco_customer_churn.csv'
MODEL = 'models/churn_model.joblib'
NUMERIC = ['tenure', 'MonthlyCharges', 'TotalCharges']
THRESHOLD = 0.25   # chosen in the notebook (best F1, favours recall)


def load_and_clean(df):
    """Clean a raw Telco dataframe (same rules as the notebook)."""
    df = df.copy()
    df['TotalCharges'] = pd.to_numeric(df['TotalCharges'], errors='coerce').fillna(0)  # blanks = new customers
    df['SeniorCitizen'] = df['SeniorCitizen'].map({0: 'No', 1: 'Yes'})
    if 'Churn' in df:
        df['Churn'] = (df['Churn'] == 'Yes').astype(int)
    return df.drop(columns='customerID', errors='ignore')


def main():
    df = load_and_clean(pd.read_csv(DATA))
    X, y = df.drop(columns='Churn'), df['Churn']
    categorical = [c for c in X.columns if c not in NUMERIC]

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, stratify=y, random_state=42)
    pipe = Pipeline([
        ('prep', ColumnTransformer([
            ('num', StandardScaler(), NUMERIC),
            ('cat', OneHotEncoder(handle_unknown='ignore', drop='if_binary'), categorical),
        ])),
        ('model', GradientBoostingClassifier(n_estimators=200, learning_rate=0.05, max_depth=3, random_state=42)),
    ])
    pipe.fit(X_train, y_train)
    auc = roc_auc_score(y_test, pipe.predict_proba(X_test)[:, 1])
    print(f'Test ROC-AUC: {auc:.3f}')

    joblib.dump({'pipeline': pipe, 'threshold': THRESHOLD, 'model_name': 'Gradient Boosting'}, MODEL)
    print('Saved model to', MODEL)


if __name__ == '__main__':
    main()
