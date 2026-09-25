import { useEffect, useState } from 'react';
import './styles.css';
import { api, logout } from './api';

type Screen='login'|'dashboard'|'topic'|'assessment'|'result'|'analysis'|'recommendation'|'practice'|'progress';
const topics=['Factorization','Quadratic Equations'];

export default function App(){
 const [screen,setScreen]=useState<Screen>(localStorage.getItem('eduos_access_token')?'dashboard':'login');
 const [topic,setTopic]=useState('Factorization'),[email,setEmail]=useState(''),[password,setPassword]=useState(''),[answer,setAnswer]=useState('');
 const [loading,setLoading]=useState(false),[error,setError]=useState(''),[usingMock,setUsingMock]=useState(false);
 const [student,setStudent]=useState<any>(null),[twin,setTwin]=useState<any>(null),[attempt,setAttempt]=useState<any>(null),[question,setQuestion]=useState<any>(null),[result,setResult]=useState<any>(null),[analysis,setAnalysis]=useState<any>(null),[recommendation,setRecommendation]=useState<any>(null);

 const run=async<T>(work:()=>Promise<T>,fallback:T|null=null)=>{
  setLoading(true);setError('');
  try{return await work()}catch(e){setError(e instanceof Error?e.message:'Something went wrong');if(fallback!==null){setUsingMock(true);return fallback}return null}finally{setLoading(false)}
 };
 useEffect(()=>{if(screen==='dashboard'&&localStorage.getItem('eduos_access_token'))void run(async()=>{const [s,t]=await Promise.all([api.student(),api.twin()]);setStudent(s);setTwin(t);return true},true)},[screen]);
 const signIn=async()=>{if(!email||!password){setError('Enter email and password.');return}const data=await run(()=>api.login(email,password));if(data){setUsingMock(false);setScreen('dashboard')}};
 const startAssessment=async()=>{const assessments=await run(()=>api.assessments(),[]);const list=Array.isArray(assessments)?assessments:[];const selected=list.find((x:any)=>String(x?.name??x?.title??'').toLowerCase().includes(topic.toLowerCase()));if(selected?.id){const a=await run(()=>api.start(String(selected.id)));const qs=await run(()=>api.questions(String(selected.id)),[]);setAttempt(a);setQuestion(Array.isArray(qs)?qs[0]:null)}setScreen('assessment')};
 const submitAnswer=async()=>{if(!attempt?.attempt_id||!question?.id){setScreen('result');return}await run(()=>api.answer(String(attempt.attempt_id),{question_id:String(question.id),student_answer:answer,time_taken_seconds:0}));const r=await run(()=>api.submit(String(attempt.attempt_id)));setResult(r);setScreen('result')};
 const openAnalysis=async()=>{const id=result?.answer_id||result?.answers?.[0]?.id;if(id)setAnalysis(await run(()=>api.mindtrace(String(id))));setScreen('analysis')};
 const openRecommendation=async()=>{const id=analysis?.concept_id||analysis?.concept?.id;if(id)setRecommendation(await run(()=>api.pathai(String(id))));setScreen('recommendation')};
 const nav=(s:Screen)=>{setError('');setScreen(s)};

 return <main className="app">
  <header><div className="brand">Edu<span>OS</span></div>{screen!=='login'&&<div><button className="ghost" onClick={()=>nav('dashboard')}>Dashboard</button><button className="ghost" onClick={()=>{logout();setScreen('login')}}>Logout</button></div>}</header>
  {loading&&<div className="loading">Connecting to EduOS backend…</div>}{error&&<div className="error">{error}{usingMock&&' Demo fallback is active.'}</div>}
  <section className="shell">
   {screen==='login'&&<div className="card hero"><p className="eyebrow">AI-powered learning platform</p><h1>Learn smarter.<br/>Understand deeper.</h1><p className="muted">Personalized assessment, misconception analysis and targeted practice for Grade 10 Mathematics.</p><input value={email} onChange={e=>setEmail(e.target.value)} placeholder="Student email"/><input type="password" value={password} onChange={e=>setPassword(e.target.value)} placeholder="Password"/><button onClick={signIn} disabled={loading}>Sign in →</button></div>}
   {screen==='dashboard'&&<><p className="eyebrow">STUDENT DASHBOARD</p><h1>{student?.display_name?'Good morning, '+student.display_name+' 👋':'Good morning 👋'}</h1><div className="grid"><div className="card"><span>Overall mastery</span><strong>{twin?.overall_mastery??twin?.mastery??68}%</strong><div className="bar"><i style={{width:String(Number(twin?.overall_mastery??twin?.mastery??68))+'%'}}/></div></div><div className="card"><span>Current focus</span><strong>Factorization</strong><p className="muted">Personalized from your learning twin.</p></div></div><button onClick={()=>nav('topic')}>Start SmartAssess →</button></>}
   {screen==='topic'&&<><p className="eyebrow">MATHEMATICS · GRADE 10</p><h1>Choose a topic</h1><div className="grid">{topics.map(t=><button className={'topic '+(topic===t?'selected':'')} onClick={()=>setTopic(t)} key={t}><b>{t}</b><span>Adaptive assessment</span></button>)}</div><button onClick={startAssessment} disabled={loading}>Begin {topic} Assessment →</button></>}
   {screen==='assessment'&&<><p className="eyebrow">SMARTASSESS · {topic}</p><h1>Question 1</h1><div className="card question"><p>{question?.question_text??question?.text??'Factorize'}</p><h2>{question?.question??'x² + 5x + 6'}</h2><input value={answer} onChange={e=>setAnswer(e.target.value)} placeholder="Enter your answer"/><button onClick={submitAnswer} disabled={loading}>Submit Answer</button></div></>}
   {screen==='result'&&<><p className="eyebrow">ASSESSMENT RESULT</p><h1>Answer submitted</h1><div className="card"><strong>{result?.score!=null?'Score: '+result.score:'Analysis ready'}</strong><p className="muted">Your response has been processed by the learning engine.</p><button onClick={openAnalysis} disabled={loading}>View AI Analysis →</button></div></>}
   {screen==='analysis'&&<><p className="eyebrow">MINDTRACE</p><h1>Understand your result</h1><div className="card"><label>Result</label><h2>{analysis?.is_correct===true?'Correct':'Needs review'}</h2><label>Misconception</label><p>{analysis?.misconception?.title??analysis?.misconception_title??'No misconception detail available yet.'}</p><label>Root cause</label><p>{analysis?.misconception?.description??analysis?.recommended_action??'Review the concept and retry targeted practice.'}</p><label>Confidence</label><div className="confidence">{Math.round(Number(analysis?.misconception?.confidence??0.8)*100)}%</div></div><button onClick={openRecommendation} disabled={loading}>See Learning Recommendation →</button></>}
   {screen==='recommendation'&&<><p className="eyebrow">PATHAI</p><h1>Your next step</h1><div className="card"><h2>{recommendation?.action??'Targeted Factorization Practice'}</h2><p className="muted">{recommendation?.reason??'Practice the identified concept before reassessment.'}</p><div className="pill">{recommendation?.duration_minutes??5} min</div></div><button onClick={()=>nav('practice')}>Start Practice →</button></>}
   {screen==='practice'&&<><p className="eyebrow">TARGETED PRACTICE</p><h1>Build the concept</h1><div className="card"><p>Which pair of integers multiplies to <b>6</b> and adds to <b>5</b>?</p><div className="answers"><button onClick={()=>nav('progress')}>2 and 3</button><button onClick={()=>nav('progress')}>1 and 6</button></div></div></>}
   {screen==='progress'&&<><p className="eyebrow">EDUTWIN · PROGRESS</p><h1>Your learning twin</h1><div className="grid"><div className="card"><span>Mastery</span><strong>{twin?.overall_mastery??twin?.mastery??68}%</strong></div><div className="card"><span>Confidence</span><strong>{twin?.confidence??76}%</strong></div><div className="card"><span>Misconception</span><strong>{analysis?.misconception?.title??'See MindTrace analysis'}</strong></div><div className="card"><span>Recommended action</span><strong>{recommendation?.action??'Reassess Factorization'}</strong></div></div><button onClick={()=>nav('topic')}>Reassess →</button></>}
  </section>
 </main>;
}
