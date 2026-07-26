/// Status aksi tulis (bayar / bayar-multiple / bayar-online).
/// Dipakai bersama oleh `KeuanganBloc` dan `KeuanganDetailBloc`.
enum KeuanganAksiStatus { idle, loading, success, failure }
