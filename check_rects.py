from pypdf import PdfReader
reader = PdfReader('form_not_working.pdf')

print('=== CHECKING RECT IN ACROFORM FIELDS ===')
for i, f in enumerate(reader.trailer['/Root']['/AcroForm']['/Fields']):
    fobj = f.get_object()
    name = fobj.get('/T')
    rect = fobj.get('/Rect')
    kids = fobj.get('/Kids')
    print(f'Field {i}: T={name}, Rect={rect}, Kids={len(kids) if kids else 0}')
    if kids:
        for ki, k in enumerate(kids):
            kobj = k.get_object()
            print(f'   Kid {ki}: T={kobj.get("/T")}, Rect={kobj.get("/Rect")}')
