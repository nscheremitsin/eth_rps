def gen(choice: str):
    d = {
        'r': 1,
        'p': 2,
        's': 3,
    }
    c = d[choice]
    from hashlib import sha256
    from random import randint
    n = randint(10 ** 50, 10 ** 51 - 1)
    s = str(c) + str(n)
    h = sha256(s.encode()).hexdigest()
    print('Choice:', c, 'Num:', n, 'Hash:', f'0x{h}', sep='\n')
