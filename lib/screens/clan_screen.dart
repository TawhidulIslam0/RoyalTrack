import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_settings.dart';
import '../utils/formatters.dart';
import '../widgets/app_header.dart';
import '../widgets/async_state.dart';

class ClanScreen extends StatefulWidget {const ClanScreen({super.key});@override State<ClanScreen> createState()=>_ClanScreenState();}
class _ClanScreenState extends State<ClanScreen>{
 final ctrl=TextEditingController();Map<String,dynamic>? clan;List<dynamic> members=[];Object? error;bool loading=false;
 Future<void> search()async{setState(()=>loading=true);try{final c=await ApiService.instance.clan(ctrl.text);final m=await ApiService.instance.clanMembers(ctrl.text);if(!mounted)return;setState(()=>clan=c);setState(()=>members=m);error=null;}catch(e){if(mounted)setState(()=>error=e);}finally{if(mounted)setState(()=>loading=false);}}
 @override void dispose(){ctrl.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>SafeArea(child:ListView(padding:const EdgeInsets.only(bottom:24),children:[
 const AppHeader(subtitle:'Clan details and roster'),
 Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:Row(children:[Expanded(child:TextField(controller:ctrl,decoration:const InputDecoration(hintText:'Clan tag',prefixIcon:Icon(Icons.search),border:OutlineInputBorder()),textCapitalization:TextCapitalization.characters,onSubmitted:(_)=>search())),const SizedBox(width:8),FilledButton(onPressed:loading?null:search,child:const Text('Search'))])),
 if(loading)const LoadingView(label:'Loading clan and members…'),if(error!=null&&!loading)ErrorView(error:error!,onRetry:search),
 if(clan!=null&&!loading)...[
 Padding(padding:const EdgeInsets.all(16),child:Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 Text(safeString(clan!['name']),style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.bold)),
 Text(safeString(clan!['tag'])),if(clan!['description']!=null)Padding(padding:const EdgeInsets.only(top:8),child:Text(clan!['description'].toString())),
 const SizedBox(height:12),Wrap(spacing:8,children:[_stat('Clan score',clan!['clanScore']),_stat('Members',clan!['members']),_stat('War trophies',clan!['clanWarTrophies']),_stat('Required trophies',clan!['requiredTrophies'])]),
 IconButton(onPressed:()=>AppSettings.instance.toggleFavorite(clan!['tag'].toString()),icon:const Icon(Icons.star_border,color:Colors.amber))
 ])))),
 Padding(padding:const EdgeInsets.fromLTRB(16,4,16,8),child:Text('Members (${members.length})',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold))),
 ...members.map((m)=>Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:3),child:Card(child:ListTile(leading:CircleAvatar(child:Text((m['name']??'?').toString().characters.first.toUpperCase())),title:Text(safeString(m['name'])),subtitle:Text('${m['tag']??''} • ${m['role']??'member'}'),trailing:Text('${m['trophies']??0}'))))),
 ],
 if(clan==null&&!loading&&error==null)const EmptyView(message:'Enter a clan tag to view its real profile and roster.')
 ]));
 Widget _stat(String l,dynamic v)=>Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:Theme.of(context).colorScheme.surfaceContainerHighest,borderRadius:BorderRadius.circular(12)),child:Column(children:[Text(number(v),style:const TextStyle(fontWeight:FontWeight.bold)),Text(l,style:Theme.of(context).textTheme.labelSmall)]));
}
