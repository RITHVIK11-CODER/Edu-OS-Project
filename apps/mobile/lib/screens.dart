import 'package:flutter/material.dart';
import 'components.dart';
import 'mock_services.dart';
import 'models.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.session});
  final StudentSession session;
  @override State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final email=TextEditingController(text:'student@eduos.app');
  final password=TextEditingController(text:'demo123');
  bool loading=false; String? error;
  @override void dispose(){email.dispose();password.dispose();super.dispose();}
  Future<void> submit() async {
    setState(()=>loading=true);
    final ok=await MockAuthService().login(email.text,password.text);
    if(!mounted)return;
    if(!ok){setState(()=>{loading=false,error='Enter a valid email and password.'});return;}
    Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>DashboardScreen(session:widget.session)));
  }
  @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:480),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    const Icon(Icons.psychology_alt_rounded,size:64),const SizedBox(height:16),
    Text('EduOS',style:Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight:FontWeight.w900)),
    const SizedBox(height:8),const Text('Learn anywhere. Test anywhere. Improve everywhere.'),const SizedBox(height:36),
    Text('Student Login',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:18),
    TextField(controller:email,decoration:const InputDecoration(labelText:'Email',prefixIcon:Icon(Icons.email_outlined))),const SizedBox(height:14),
    TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'Password',prefixIcon:Icon(Icons.lock_outline))),
    if(error!=null)Padding(padding:const EdgeInsets.only(top:12),child:Text(error!,style:TextStyle(color:Colors.red))),const SizedBox(height:22),
    PrimaryButton(label:loading?'Signing in...':'Continue as Student',icon:Icons.login_rounded,onPressed:loading?null:submit),const SizedBox(height:12),
    const Text('Demo mode uses a local mock service. Real authentication will use the backend contract.',style:TextStyle(color:Colors.black54)),
  ]))))));
}

class DashboardScreen extends StatelessWidget {
 const DashboardScreen({super.key,required this.session}); final StudentSession session;
 @override Widget build(BuildContext context)=>AnimatedBuilder(animation:session,builder:(context,_)=>Scaffold(appBar:AppBar(title:const Text('EduOS'),actions:[IconButton(tooltip:'EduTwin',onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ProgressScreen(session:session))),icon:const Icon(Icons.insights_rounded))]),body:ListView(padding:const EdgeInsets.all(20),children:[
  Text('Good morning, Student 👋',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:6),const Text('Your learning path adapts to what you need next.'),const SizedBox(height:20),
  Card(elevation:0,child:ListTile(contentPadding:const EdgeInsets.all(18),leading:CircularProgressIndicator(value:session.overallMastery/100),title:const Text('EduTwin',style:TextStyle(fontWeight:FontWeight.w800)),subtitle:Text('Overall mastery: '+session.overallMastery.toString()+'%'))),const SizedBox(height:18),
  Text('Continue learning',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:10),
  _ActionCard(icon:Icons.functions_rounded,title:'Grade 10 Mathematics',subtitle:'Factorization • SmartAssess',onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>TopicScreen(session:session)))),const SizedBox(height:22),
  Text('Your concepts',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:8),...session.concepts.map((c)=>ProgressCard(title:c.name,value:c.mastery,status:c.status)),
])));
}

class TopicScreen extends StatelessWidget {
 const TopicScreen({super.key,required this.session}); final StudentSession session;
 Future<void> start(BuildContext context,String topic) async {final qs=await MockAssessmentService().getQuestions(topic);if(!context.mounted||qs.isEmpty)return;Navigator.push(context,MaterialPageRoute(builder:(_)=>AssessmentScreen(session:session,question:qs.first)));}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Grade 10 Mathematics')),body:ListView(padding:const EdgeInsets.all(20),children:[const EduHeader(title:'Choose a topic',subtitle:'SmartAssess adapts to your current learning state.'),const SizedBox(height:10),
  _TopicCard(title:'Factorization',mastery:session.conceptMastery['Factorization']??0,icon:Icons.account_tree_rounded,onTap:()=>start(context,'Factorization')),
  _TopicCard(title:'Quadratic Equations',mastery:session.conceptMastery['Quadratic Equations']??0,icon:Icons.show_chart_rounded,onTap:()=>start(context,'Quadratic Equations')),
])));
}

class AssessmentScreen extends StatefulWidget {
 const AssessmentScreen({super.key,required this.session,required this.question}); final StudentSession session; final AssessmentQuestion question;
 @override State<AssessmentScreen> createState()=>_AssessmentScreenState();
}
class _AssessmentScreenState extends State<AssessmentScreen>{
 final answer=TextEditingController(),reasoning=TextEditingController(); bool submitting=false;
 @override void dispose(){answer.dispose();reasoning.dispose();super.dispose();}
 Future<void> submit() async {if(answer.text.trim().isEmpty)return;setState(()=>submitting=true);final r=await MockAIAnalysisService().analyze(question:widget.question,answer:answer.text,reasoning:reasoning.text);if(!mounted)return;widget.session.setAnalysis(r);Navigator.push(context,MaterialPageRoute(builder:(_)=>ResultScreen(session:widget.session,question:widget.question,result:r)));}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('SmartAssess')),body:ListView(padding:const EdgeInsets.all(20),children:[InfoChip(label:widget.question.topic,icon:Icons.menu_book_rounded),const SizedBox(height:18),Text(widget.question.question,style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:22),TextField(controller:answer,decoration:const InputDecoration(labelText:'Your answer')),const SizedBox(height:14),TextField(controller:reasoning,maxLines:4,decoration:const InputDecoration(labelText:'Optional reasoning')),const SizedBox(height:20),PrimaryButton(label:submitting?'Analyzing...':'Submit Answer',icon:Icons.send_rounded,onPressed:submitting?null:submit),const SizedBox(height:12),Text(widget.question.reasoningHint??'',style:const TextStyle(color:Colors.black54))]));
}

class ResultScreen extends StatelessWidget {
 const ResultScreen({super.key,required this.session,required this.question,required this.result}); final StudentSession session; final AssessmentQuestion question; final MindTraceResult result;
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Assessment Result')),body:ListView(padding:const EdgeInsets.all(20),children:[Card(elevation:0,child:Padding(padding:const EdgeInsets.all(20),child:Column(children:[Icon(result.isCorrect?Icons.check_circle_rounded:Icons.error_rounded,size:58),Text(result.isCorrect?'Correct':'Incorrect',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w900)),Text(question.topic)]))),const SizedBox(height:16),_DetailCard(title:'MindTrace analysis',children:[_DetailRow('Misconception',result.misconception),_DetailRow('Root cause',result.rootCause),_DetailRow('Evidence',result.evidence),_DetailRow('Confidence',(result.confidence*100).round().toString()+'%')]),const SizedBox(height:16),PrimaryButton(label:'See Personalized Recommendation',icon:Icons.track_changes_rounded,onPressed:()async{final rec=await MockRecommendationService().recommend(question.topic);session.setRecommendation(rec);if(!context.mounted)return;Navigator.push(context,MaterialPageRoute(builder:(_)=>RecommendationScreen(session:session)));})]));
}

class RecommendationScreen extends StatelessWidget {
 const RecommendationScreen({super.key,required this.session}); final StudentSession session;
 @override Widget build(BuildContext context){final r=session.recommendation;return Scaffold(appBar:AppBar(title:const Text('PathAI')),body:ListView(padding:const EdgeInsets.all(20),children:[const EduHeader(title:'Your next best action',subtitle:'A focused recovery plan based on your latest attempt.'),Card(elevation:0,child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const InfoChip(label:'PERSONALIZED',icon:Icons.auto_awesome_rounded),const SizedBox(height:14),Text(r?.action??'Review the concept',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w900)),const SizedBox(height:8),Text(r?.reason??''),const SizedBox(height:14),if(r!=null)...r.steps.map((s)=>ListTile(contentPadding:EdgeInsets.zero,leading:const Icon(Icons.check_circle_outline_rounded),title:Text(s)))]))),const SizedBox(height:16),PrimaryButton(label:'Start Practice',icon:Icons.school_rounded,onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>PracticeScreen(session:session))))]));}
}

class PracticeScreen extends StatefulWidget {const PracticeScreen({super.key,required this.session});final StudentSession session;@override State<PracticeScreen> createState()=>_PracticeScreenState();}
class _PracticeScreenState extends State<PracticeScreen>{final answer=TextEditingController();bool submitted=false;final q=const AssessmentQuestion(id:'p1',topic:'Factorization',question:'Factorize x² + 7x + 12',expectedAnswer:'(x + 3)(x + 4)');@override void dispose(){answer.dispose();super.dispose();}@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Practice')),body:ListView(padding:const EdgeInsets.all(20),children:[const InfoChip(label:'Targeted Practice',icon:Icons.bolt_rounded),const SizedBox(height:16),Text(q.question,style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:18),TextField(controller:answer,decoration:const InputDecoration(labelText:'Your answer')),if(submitted)Padding(padding:const EdgeInsets.symmetric(vertical:16),child:Text(answer.text.trim().toLowerCase()==q.expectedAnswer.toLowerCase()?'Nice work. You are ready for reassessment.':'Try the factor-pair idea again.')),PrimaryButton(label:submitted?'Go to Reassessment':'Check Practice',onPressed:(){if(!submitted)setState(()=>submitted=true);else Navigator.push(context,MaterialPageRoute(builder:(_)=>ReassessmentScreen(session:session)));})]));}

class ReassessmentScreen extends StatefulWidget {const ReassessmentScreen({super.key,required this.session});final StudentSession session;@override State<ReassessmentScreen> createState()=>_ReassessmentScreenState();}
class _ReassessmentScreenState extends State<ReassessmentScreen>{final answer=TextEditingController();bool submitted=false,correct=false;@override void dispose(){answer.dispose();super.dispose();}void submit(){final v=answer.text.trim().toLowerCase();correct=v=='(x + 2)(x + 3)'||v=='x = 2, 3';setState(()=>submitted=true);if(correct)widget.session.applyReassessment(concept:widget.session.lastAnalysis?.concept??'Factorization',correct:true);}@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Reassessment')),body:ListView(padding:const EdgeInsets.all(20),children:[const InfoChip(label:'Reassess',icon:Icons.refresh_rounded),const SizedBox(height:16),Text('Factorize x² + 5x + 6',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:18),TextField(controller:answer,decoration:const InputDecoration(labelText:'Your answer')),if(submitted)Padding(padding:const EdgeInsets.symmetric(vertical:18),child:Text(correct?'Great job! Your learning state improved.':'Not quite yet. Review the concept and try again.',style:const TextStyle(fontWeight:FontWeight.w700))),PrimaryButton(label:submitted?'View Updated EduTwin':'Submit Reassessment',icon:Icons.send_rounded,onPressed:submitted?()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ProgressScreen(session:widget.session))):submit)]));}

class ProgressScreen extends StatelessWidget {const ProgressScreen({super.key,required this.session});final StudentSession session;@override Widget build(BuildContext context)=>AnimatedBuilder(animation:session,builder:(context,_)=>Scaffold(appBar:AppBar(title:const Text('EduTwin')),body:ListView(padding:const EdgeInsets.all(20),children:[const EduHeader(title:'Your learning state',subtitle:'Progress changes as you practice and reassess.'),Card(elevation:0,child:Padding(padding:const EdgeInsets.all(20),child:Text('Overall mastery '+session.overallMastery.toString()+'%',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)))),const SizedBox(height:12),...session.concepts.map((c)=>ProgressCard(title:c.name,value:c.mastery,status:c.status)),if(session.lastAnalysis!=null)_DetailCard(title:'Latest MindTrace signal',children:[_DetailRow('Concept',session.lastAnalysis!.concept),_DetailRow('Misconception',session.lastAnalysis!.misconception)])])));}

class _ActionCard extends StatelessWidget {const _ActionCard({required this.icon,required this.title,required this.subtitle,required this.onTap});final IconData icon;final String title,subtitle;final VoidCallback onTap;@override Widget build(BuildContext context)=>Card(elevation:0,child:ListTile(onTap:onTap,contentPadding:const EdgeInsets.all(16),leading:CircleAvatar(child:Icon(icon)),title:Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text(subtitle),trailing:const Icon(Icons.arrow_forward_ios_rounded,size:17)));}
class _TopicCard extends StatelessWidget {const _TopicCard({required this.title,required this.mastery,required this.icon,required this.onTap});final String title;final int mastery;final IconData icon;final VoidCallback onTap;@override Widget build(BuildContext context)=>Card(elevation:0,margin:const EdgeInsets.only(bottom:12),child:ListTile(onTap:onTap,contentPadding:const EdgeInsets.all(16),leading:CircleAvatar(child:Icon(icon)),title:Text(title,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text(mastery.toString()+'% current mastery'),trailing:const Icon(Icons.play_circle_outline_rounded)));}
class _DetailCard extends StatelessWidget {const _DetailCard({required this.title,required this.children});final String title;final List<Widget> children;@override Widget build(BuildContext context)=>Card(elevation:0,child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w800)),const SizedBox(height:10),...children])));}
class _DetailRow extends StatelessWidget {const _DetailRow(this.label,this.value);final String label,value;@override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(bottom:12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(fontWeight:FontWeight.w700)),const SizedBox(height:3),Text(value)]));}