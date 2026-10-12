import json, sys
W=105
fr=json.load(open(sys.argv[1]))
team_of={}
segs=[]; cur=None
for f in fr:
    o=f['o']
    if o>=0:
        t=0 if o<11 else 1
        if cur is None or cur['team']!=t:
            if cur: segs.append(cur)
            cur={'team':t,'t0':f['t'],'max':0,'shot':False,'box':False,'n':0}
    if cur:
        d0=f['d0']; dirt = d0 if cur['team']==0 else -d0
        bx=f['b'][0] if dirt>0 else W-f['b'][0]
        cur['t1']=f['t']
        if o>=0 and (0 if o<11 else 1)==cur['team']:
            cur['max']=max(cur['max'],bx)
            if bx>W-16.5 and abs(f['b'][1]-34)<20: cur['box']=True
        if f['ev']=='remate': cur['shot']=True
if cur: segs.append(cur)
n=len(segs)
print('posses',n,'dur media %.1f s'%(sum(s['t1']-s['t0'] for s in segs)/n))
for lim in (52.5,70,80,88.5):
    k=[s for s in segs if s['max']>lim]
    print('chega a %.0f m: %d (%.0f%%), com remate %d'%(lim,len(k),100*len(k)/n,sum(1 for s in k if s['shot'])))
print('entra na area',sum(1 for s in segs if s['box']),' remates total',sum(1 for s in segs if s['shot']))
