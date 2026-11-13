import sys,struct,hashlib
b=open(sys.argv[1],'rb').read(); k=open(sys.argv[2],'rb').read()
ks,ka,rs,ra,ss,sa,ta,ps,dts=struct.unpack('<9I',b[8:44]); pad=lambda n:(n+ps-1)//ps*ps
o=ps; o+=pad(ks); ram=b[o:o+rs]; o+=pad(rs); sec=b[o:o+ss]; o+=pad(ss); dt=b[o:o+dts]; o+=pad(dts); tail=b[o:]
h=bytearray(b[:ps]); struct.pack_into('<I',h,8,len(k)); sha=hashlib.sha1()
for x in (k,ram,sec,dt): sha.update(x); sha.update(struct.pack('<I',len(x)))
h[576:608]=sha.digest().ljust(32,b'\0'); p=lambda x:x+b'\0'*(pad(len(x))-len(x))
open(sys.argv[3],'wb').write(bytes(h)+p(k)+p(ram)+(p(sec) if ss else b'')+p(dt)+tail)
