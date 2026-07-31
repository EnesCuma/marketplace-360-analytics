# Marketplace 360 Analytics

Bu projeyi SQL Server ve Power BI becerilerimi gerçek bir e-ticaret veri seti üzerinde geliştirmek; satış, müşteri ve operasyon verilerinden anlamlı sonuçlar çıkarabildiğimi göstermek amacıyla hazırlıyorum.

Projede Olist pazar yerine ait sipariş, müşteri, ürün, satıcı, ödeme, teslimat ve değerlendirme verileri kullanılacaktır. Ham veriler SQL Server üzerinde düzenlenecek, SQL sorgularıyla analiz edilecek ve sonuçlar Power BI dashboard'larına aktarılacaktır.

## Projenin Amacı

Bir e-ticaret pazar yerinin performansını farklı açılardan inceleyen bir raporlama çalışması oluşturmak:

- Satış ve sipariş eğilimlerini takip etmek
- Ürün kategorilerinin performansını karşılaştırmak
- Müşteri davranışlarını incelemek
- Satıcıların satış ve teslimat performansını ölçmek
- Teslimat gecikmelerini analiz etmek
- Müşteri değerlendirmeleriyle operasyonel performans arasındaki ilişkiyi araştırmak
- Yönetim tarafından takip edilebilecek temel KPI'ları tek bir raporda toplamak

## Cevap Aranan İş Soruları

Proje kapsamında aşağıdaki sorulara yanıt aranacaktır:

1. Sipariş hacmi ve satış değeri zaman içerisinde nasıl değişmektedir?
2. En fazla satış üreten ürün kategorileri hangileridir?
3. Hangi bölgelerde daha fazla sipariş verilmektedir?
4. Ortalama sipariş tutarı ve ödeme davranışları nasıldır?
5. Müşterilerin ne kadarı birden fazla sipariş vermektedir?
6. Hangi satıcılar satış ve teslimat performansında öne çıkmaktadır?
7. Siparişlerin ortalama teslimat süresi ne kadardır?
8. Tahmini teslimat tarihini aşan siparişlerin oranı nedir?
9. Teslimat gecikmeleri müşteri değerlendirme puanlarını etkiliyor mu?
10. Düşük müşteri puanlarının yoğunlaştığı kategori, satıcı veya bölgeler var mı?

## Kullanılan Teknolojiler

- SQL Server 2025
- SQL Server Management Studio
- Power BI Desktop
- Power Query
- DAX
- Git ve GitHub
- Gerektiğinde veri doğrulama için Python ve Pandas

## Veri Seti

Projede **Brazilian E-Commerce Public Dataset by Olist** kullanılacaktır.

Veri seti, Brezilya'daki bir e-ticaret pazar yerine ait anonimleştirilmiş siparişlerden oluşmaktadır. Siparişler, müşteriler, ürünler, satıcılar, ödemeler, değerlendirmeler ve konum bilgileri farklı CSV dosyalarında tutulmaktadır.

Projede kullanılması planlanan temel tablolar:

- Orders
- Order Items
- Customers
- Products
- Sellers
- Payments
- Reviews
- Product Category Translation

Ham CSV dosyaları depo boyutunu büyütmemek amacıyla GitHub'a yüklenmeyecektir. Verilerin hangi kaynaktan indirileceği ve hangi klasöre yerleştirileceği proje tamamlandığında ayrıca açıklanacaktır.

## Veriyle İlgili Önemli Not

Veri setinde pazar yerinin komisyon oranı, ürün maliyetleri ve şirket giderleri bulunmamaktadır. Bu nedenle ürün fiyatlarının toplamı gerçek şirket geliri veya net kâr olarak değil, **GMV — platform üzerinden gerçekleşen toplam ürün satış değeri** olarak değerlendirilecektir.

Ayrıca stok hareketleri, reklam harcamaları ve web sitesi ziyaret verileri bulunmadığı için stok tükenmesi, ROAS, dönüşüm oranı ve sepet terk etme oranı gibi metrikler hesaplanmayacaktır.

## Proje Akışı

```text
Olist CSV Files
        ↓
SQL Server Tables
        ↓
Data Quality Checks
        ↓
Data Cleaning and Transformation
        ↓
Analysis Views and SQL Queries
        ↓
Power BI Data Model
        ↓
Interactive Dashboards
        ↓
Business Insights
```

## SQL Çalışmaları

SQL tarafında aşağıdaki konuların kullanılması planlanmaktadır:

- Tablo oluşturma ve veri türü seçimi
- Primary key ve foreign key ilişkileri
- Veri kalite kontrolleri
- Eksik ve tekrarlı kayıt analizi
- JOIN işlemleri
- GROUP BY ve toplulaştırma
- CASE WHEN ifadeleri
- Tarih ve zaman fonksiyonları
- Common Table Expressions
- Window functions
- Analiz view'ları
- İş odaklı KPI sorguları

Planlanan SQL dosyaları:

```text
sql/
├── 01_create_database.sql
├── 02_create_tables.sql
├── 03_import_data.sql
├── 04_data_quality_checks.sql
├── 05_create_analysis_views.sql
└── 06_business_queries.sql
```

## Power BI Raporu

Raporun üç ana sayfadan oluşması planlanmaktadır.

### 1. Executive Overview

- Toplam GMV
- Toplam sipariş
- Toplam müşteri
- Ortalama sipariş tutarı
- Ortalama değerlendirme puanı
- Aylık sipariş ve satış eğilimi
- En yüksek performanslı kategoriler
- Bölgesel satış dağılımı

### 2. Sales and Product Analysis

- Kategori bazında GMV
- Sipariş ve ürün adedi
- Aylık performans değişimi
- Ödeme yöntemleri
- Taksit kullanımı
- Satıcı bazında satış performansı
- En güçlü ve en zayıf kategoriler

### 3. Delivery and Customer Experience

- Ortalama teslimat süresi
- Geciken sipariş oranı
- Bölgesel teslimat performansı
- Değerlendirme puanı dağılımı
- Gecikme ve müşteri puanı ilişkisi
- Düşük puanlı siparişlerin analizi
- Satıcı bazında teslimat performansı

## Klasör Yapısı

```text
marketplace-360-analytics/
├── data/
│   └── raw/
├── docs/
├── images/
├── notebooks/
├── powerbi/
├── sql/
│   └── 01_create_database.sql
├── .gitignore
└── README.md
```

## Proje Durumu

- [x] SQL Server kurulumu
- [x] SQL Server Management Studio kurulumu
- [x] Power BI Desktop kurulumu
- [x] Marketplace360 veritabanının oluşturulması
- [x] Proje klasör yapısının hazırlanması
- [x] Yerel Git deposunun başlatılması
- [ ] GitHub deposunun oluşturulması
- [ ] Olist veri setinin indirilmesi
- [ ] Veri tablolarının incelenmesi
- [ ] CSV dosyalarının SQL Server'a aktarılması
- [ ] Veri kalite kontrollerinin yapılması
- [ ] Analiz view'larının hazırlanması
- [ ] İş odaklı SQL sorgularının yazılması
- [ ] Power BI veri modelinin kurulması
- [ ] DAX ölçülerinin hazırlanması
- [ ] Dashboard sayfalarının tamamlanması
- [ ] Bulguların ve ekran görüntülerinin README'ye eklenmesi

## Proje Tamamlandığında Eklenecekler

Projenin final sürümünde bu README dosyasına aşağıdaki bölümler eklenecektir:

- Power BI dashboard ekran görüntüleri
- Veri modeli görünümü
- Kullanılan temel DAX ölçüleri
- Öne çıkan SQL sorguları
- Elde edilen temel bulgular
- Yönetim için hazırlanmış öneriler
- Projeyi yerel ortamda çalıştırma adımları

## Geliştirici

**Enes Cuma Kahraman**

Bilgisayar Programcılığı mezunu ve Gazi Üniversitesi İstatistik Bölümü öğrencisi. Veri analizi, iş zekâsı, finans ve operasyon analitiği alanlarında kendini geliştirmektedir.