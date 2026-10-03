"""
Score new customers with the saved churn model.

Usage:  python src/predict.py path/to/new_customers.csv
        (the CSV must have the same columns as the training data; a 'Churn' column is optional)
Output: outputs/predictions.csv with churn probability and risk segment for every customer
"""
import sys

import joblib
import pandas as pd

from train import load_and_clean

MODEL = 'models/churn_model.joblib'


def main(path):
    bundle = joblib.load(MODEL)
    pipe, threshold = bundle['pipeline'], bundle['threshold']

    raw = pd.read_csv(path)
    X = load_and_clean(raw).drop(columns='Churn', errors='ignore')

    out = pd.DataFrame({'customerID': raw['customerID']}) if 'customerID' in raw else pd.DataFrame(index=raw.index)
    out['churn_probability'] = pipe.predict_proba(X)[:, 1].round(3)
    out['will_churn'] = (out['churn_probability'] >= threshold).map({True: 'Yes', False: 'No'})
    out['risk_segment'] = pd.cut(out['churn_probability'], [0, 0.3, 0.6, 1.0],
                                 labels=['Low', 'Medium', 'High'], include_lowest=True)
    out.sort_values('churn_probability', ascending=False).to_csv('outputs/predictions.csv', index=False)
    print(out['risk_segment'].value_counts())
    print('Saved outputs/predictions.csv')


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else 'data/telco_customer_churn.csv')
