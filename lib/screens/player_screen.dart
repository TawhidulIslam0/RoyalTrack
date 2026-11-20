import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_settings.dart';
import '../utils/formatters.dart';
import '../widgets/async_state.dart';
import '../widgets/app_header.dart';

class PlayerScreen extends StatefulWidget { const PlayerScreen({super.key}); @override State<PlayerScreen> createState()=>_PlayerScreenState(); }
class _PlayerScreenState extends State<PlayerScreen> {
 final tagCtrl=TextEditingController(); Map<String,dynamic>? player; List<dynamic> battles=[]; Object? error; bool loading=false;
 Future<void> search() async { setState(()=>loading=true); try { final p=await ApiService.instance.player(tagCtrl.text); final b=await ApiService.instance.battles(tagCtrl.text); if(!mounted)return; setState(()=>player=p); setState(()=>battles=b); error=null; } catch(e){if(mounted)setState(()=>error=e);} finally{if(mounted)setState(()=>loading=false);} }
 @override void dispose(){tagCtrl.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>SafeArea(child:ListView(padding:const EdgeInsets.only(bottom:24),children:[
 const AppHeader(subtitle:'Player profiles and battle history'),
 Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:Row(children:[Expanded(child:TextField(controller:tagCtrl,decoration:const InputDecoration(hintText:'Player tag (e.g. #ABC123)',border:OutlineInputBorder(),prefixIcon:Icon(Icons.search)),textCapitalization:TextCapitalization.characters,onSubmitted:(_)=>search())),const SizedBox(width:8),FilledButton(onPressed:loading?null:search,child:const Text('Search'))])),
 if(loading)const LoadingView(label:'Fetching player and battle log…'),
 if(error!=null&&!loading)ErrorView(error:error!,onRetry:search),
 if(player!=null&&!loading)...[
 _profileCard(context),
 Padding(padding:const EdgeInsets.all(16),child:Text('Recent battles',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold))),
 if(battles.isEmpty)const EmptyView(message:'No battle-log data was returned for this player.') else ...battles.take(20).map((b)=>_battleCard(context,b)),
 ],
 if(player==null&&!loading&&error==null)const EmptyView(message:'Enter a player tag above to load a real profile.'),
 ]));
 Widget _profileCard(BuildContext context){final p=player!;final clan=p['clan'];final fav=AppSettings.instance.isFavorite(p['tag']?.toString()??tagCtrl.text);
 return Padding(padding:const EdgeInsets.all(16),child:Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 Row(children:[Expanded(child:Text(safeString(p['name']),style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w900))),IconButton(icon:Icon(fav?Icons.star:Icons.star_border,color:Colors.amber),onPressed:()=>AppSettings.instance.toggleFavorite(p['tag']?.toString()??tagCtrl.text))]),
 Text(safeString(p['tag']),style:Theme.of(context).textTheme.bodySmall),if(clan is Map)Text('Clan: ${clan['name']??'—'}  ${clan['tag']??''}'),
 const SizedBox(height:12),Wrap(spacing:8,runSpacing:8,children:[_stat('Trophies',p['trophies']),_stat('Best',p['bestTrophies']),_stat('Wins',p['wins']),_stat('Losses',p['losses']),_stat('3-crown',p['threeCrownWins']),_stat('Donations',p['totalDonations'])]),
 const SizedBox(height:14),Text('Current deck',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.bold)),
 if(p['currentDeck'] is List)Wrap(spacing:4,runSpacing:4,children:(p['currentDeck'] as List).map((c)=>_cardChip(c)).toList()) else const Text('Current deck unavailable'),
 ]))));
 }
 Widget _stat(String label,dynamic value)=>Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:9),decoration:BoxDecoration(color:Theme.of(context).colorScheme.surfaceContainerHighest,borderRadius:BorderRadius.circular(12)),child:Column(children:[Text(number(value),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:16)),Text(label,style:Theme.of(context).textTheme.labelSmall)]));
 Widget _cardChip(dynamic c){final url=cardImage(c);return SizedBox(width:65,child:Column(children:[if(url.isNotEmpty)Image.network(url,height:70,fit:BoxFit.contain,errorBuilder:(_,__,___)=>const Icon(Icons.broken_image)) else const Icon(Icons.style),Text(safeString(c['name']),maxLines:2,overflow:TextOverflow.ellipsis,textAlign:TextAlign.center,style:const TextStyle(fontSize:10))]));}
 Widget _battleCard(BuildContext context,dynamic b){final team=(b['team'] as List? ?? []);final opponent=(b['opponent'] as List? ?? []);final t=team.isNotEmpty?team.first:{};final o=opponent.isNotEmpty?opponent.first:{};final result=(b['teamCrowns']??0)>(b['opponentCrowns']??0)?'Victory':(b['teamCrowns']??0)<(b['opponentCrowns']??0)?'Defeat':'Draw';return Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:4),child:Card(child:ListTile(leading:Icon(result=='Victory'?Icons.emoji_events:Icons.sports_kabaddi,color:result=='Victory'?Colors.amber:Theme.of(context).colorScheme.primary),title:Text('${t['name']??'You'} vs ${o['name']??'Opponent'}'),subtitle:Text('${b['type']??b['gameMode']?['name']??'Battle'} • ${b['teamCrowns']??0} - ${b['opponentCrowns']??0}'),trailing:Text(result,style:TextStyle(fontWeight:FontWeight.bold,color:result=='Victory'?Colors.green:Theme.of(context).colorScheme.error)))));}
}
