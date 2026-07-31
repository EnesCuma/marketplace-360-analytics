from pathlib import Path
from urllib.parse import quote_plus

import pandas as pd
from sqlalchemy import create_engine, text


PROJECT_ROOT = Path(__file__).resolve().parent
RAW_DATA_DIR = PROJECT_ROOT / "data" / "raw"

FILES = {
    "customers": "olist_customers_dataset.csv",
    "geolocation": "olist_geolocation_dataset.csv",
    "order_items": "olist_order_items_dataset.csv",
    "order_payments": "olist_order_payments_dataset.csv",
    "order_reviews": "olist_order_reviews_dataset.csv",
    "orders": "olist_orders_dataset.csv",
    "products": "olist_products_dataset.csv",
    "sellers": "olist_sellers_dataset.csv",
    "product_category_translation": "product_category_name_translation.csv",
}

odbc_connection = (
    "DRIVER={ODBC Driver 18 for SQL Server};"
    "SERVER=localhost;"
    "DATABASE=Marketplace360;"
    "Trusted_Connection=yes;"
    "TrustServerCertificate=yes;"
)

connection_url = (
    "mssql+pyodbc:///?odbc_connect="
    + quote_plus(odbc_connection)
)

engine = create_engine(
    connection_url,
    fast_executemany=True,
)


def load_csv_to_staging(table_name: str, file_name: str) -> int:
    file_path = RAW_DATA_DIR / file_name

    if not file_path.exists():
        raise FileNotFoundError(f"Dosya bulunamadı: {file_path}")

    print(f"\nYükleniyor: {file_name} -> stg.{table_name}")

    dataframe = pd.read_csv(
        file_path,
        dtype=str,
        keep_default_na=False,
        encoding="utf-8",
    )

    # Boş metinleri SQL NULL değerine dönüştür.
    dataframe = dataframe.replace("", None)

    dataframe.to_sql(
        name=table_name,
        schema="stg",
        con=engine,
        if_exists="append",
        index=False,
        chunksize=5000,
    )

    print(f"Tamamlandı: {len(dataframe):,} kayıt")
    return len(dataframe)


def main() -> None:
    loaded_rows = {}

    # Script tekrar çalıştırıldığında mükerrer veri oluşmasını önler.
    with engine.begin() as connection:
        for table_name in FILES:
            connection.execute(
                text(f"TRUNCATE TABLE stg.{table_name}")
            )

    for table_name, file_name in FILES.items():
        loaded_rows[table_name] = load_csv_to_staging(
            table_name,
            file_name,
        )

    print("\nYükleme özeti")
    print("-" * 45)

    for table_name, row_count in loaded_rows.items():
        print(f"{table_name:<30} {row_count:>10,}")

    print("\nTüm dosyalar başarıyla yüklendi.")


if __name__ == "__main__":
    main()