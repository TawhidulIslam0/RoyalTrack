import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/app_header.dart';
import '../widgets/async_state.dart';

class RankingsScreen extends StatefulWidget { const RankingsScreen({super.key}); @override State<RankingsScreen> createState()=>_RankingsScreenState(); }
class _RankingsScreenState extends State<RankingsScreen> {
  final location=TextEditingController(text:'global');
  dynamic data; bool loading=false; Object? error;
  Future<void> load() async {setState(()=>loading=true);try{final r=await ApiService.instance.rankings(location.text.trim().isEmpty?'global':location.text.trim());if(mounted)setState(()=>data=r);error=null;}catch(e){if(mounted)setState(()=>error=e);}finally{if(mounted)setState(()=>loading=false);}}
  @override void dispose(){location.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>SafeArea(child:ListView(padding:const EdgeInsets.only(bottom:24),children:[
    const AppHeader(subtitle:'Competitive rankings where supported'),
    Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:Row(children:[Expanded(child:TextField(controller:location,decoration:const InputDecoration(labelText:'Location ID',hintText:'global or location ID',border:OutlineInputBorder()),onSubmitted:(_)=>load())),const SizedBox(width:8),FilledButton(onPressed:loading?null:load,child:const Text('Load'))])),
    const Padding(padding:EdgeInsets.all(16),child:Text('Try “global” or a location ID. Rankings availability depends on the API endpoint and region.')),
    if(loading)const LoadingView(label:'Loading rankings…'),
    if(error!=null&&!loading)ErrorView(error:error!,onRetry:load),
    if(data is List&&!loading) ... (data as List).take(100).map((item)=>Card(margin:const EdgeInsets.symmetric(horizontal:16,vertical:3),child:ListTile(leading:CircleAvatar(child:Text('${item['rank']??'—'}')),title:Text(item['name']??'Player'),subtitle:Text(item['tag']??''),trailing:Text('${item['trophies']??item['score']??''}')))),
    if(data is Map&&!loading)Padding(padding:const EdgeInsets.all(16),child:Text('API response received. This endpoint may return a structured object rather than a list.')),
    if(data==null&&!loading&&error==null)const EmptyView(message:'Choose a location and load rankings.'),
  ]));
}
