import struct,os,sys
os.chdir(sys.argv[1])
PART_BLOCKS=2621440; MAXRAW=16384
src=open('gta2lab.simg','rb')
m,maj,mn,fhs,chs,bs,tb,tc,crc=struct.unpack('<IHHHHIIII',src.read(28)); src.read(fhs-28)
plan=[]
for i in range(tc):
    t,_,sz,tot=struct.unpack('<HHII',src.read(chs)[:12]); off=src.tell(); src.seek(tot-chs,1)
    kind='raw' if t in (0xcac1,0xcac2) else 'skip'
    if plan and plan[-1][0]==kind and (kind=='skip' or plan[-1][1]+sz<=MAXRAW):
        plan[-1][1]+=sz; plan[-1][2].append((off,t,sz))
    else: plan.append([kind,sz,[(off,t,sz)]])
used=sum(p[1] for p in plan)
if used<PART_BLOCKS: plan.append(['skip',PART_BLOCKS-used,[]])
out=open('userdata.img','wb')
out.write(struct.pack('<IHHHHIIII',0xed26ff3a,1,0,32,16,4096,PART_BLOCKS,len(plan),0)+b'\0'*4)
for kind,n,parts in plan:
    if kind=='raw':
        out.write(struct.pack('<HHII',0xcac1,0,n,16+n*4096)+b'\0'*4)
        for off,t,sz in parts:
            src.seek(off); out.write(src.read(sz*4096) if t==0xcac1 else src.read(4)*(sz*1024))
    else:
        out.write(struct.pack('<HHII',0xcac3,0,n,16)+b'\0'*4)
out.close()
print('chunks',len(plan),'raw',sum(1 for p in plan if p[0]=='raw'),'size',os.path.getsize('userdata.img'))
