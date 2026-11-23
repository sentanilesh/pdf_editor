from pypdf import PdfReader
reader = PdfReader('form_not_working.pdf')

print('=== FIELDS IN form_not_working.pdf ===')
fields = reader.get_fields()
for name, f in fields.items():
    print(f'Name: {name}')
    print('  FT:', f.get('/FT'))
    print('  Ff:', f.get('/Ff'))
    print('  V:', repr(f.get('/V')))
    print('  Rect:', f.get('/Rect'))
    kids = f.get('/Kids')
    print('  Kids count:', len(kids) if kids else 0)
    if kids:
        for ki, k in enumerate(kids):
            kobj = k.get_object()
            print(f'    Kid {ki}: Rect={kobj.get("/Rect")}, V={repr(kobj.get("/V"))}, AS={kobj.get("/AS")}')
    aa = f.get('/AA')
    if aa:
        print('  AA keys:', list(aa.keys()))
        for k, v in aa.items():
            act = v.get_object()
            print(f'    Action {k} ({act.get("/S")}): {repr(act.get("/JS"))}')
    a = f.get('/A')
    if a:
        act = a.get_object()
        print(f'  Action A ({act.get("/S")}): {repr(act.get("/JS"))}')
