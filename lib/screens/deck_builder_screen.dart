import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_settings.dart';
import '../utils/formatters.dart';
import '../widgets/app_header.dart';
import '../widgets/async_state.dart';

class DeckBuilderScreen extends StatefulWidget {const DeckBuilderScreen({super.key});@override State<DeckBuilderScreen> createState()=>_DeckBuilderScreenState();}
class _DeckBuilderScreenState extends State<DeckBuilderScreen>{
 List<dynamic> cards=[];final selected=<dynamic>[];bool loading=false;Object? error;String search='';
 Future<void> load()async{setState(()=>loading=true);try{final d=await ApiService.instance.cards();if(mounted)setState(()=>cards=List<dynamic>.from(d['items']??[]));error=null;}catch(e){if(mounted)setState(()=>error=e);}finally{if(mounted)setState(()=>loading=false);}}
 @override void initState(){super.initState();load();}
 double get average=>selected.isEmpty?0:selected.map(cardElixir).reduce((a,b)=>a+b)/selected.length;
 @override Widget build(BuildContext context){final visible=cards.where((c)=>(c['name']??'').toString().toLowerCase().contains(search.toLowerCase())&&!selected.any((x)=>x['id']==c['id'])).toList();return SafeArea(child:ListView(padding:const EdgeInsets.only(bottom:24),children:[
 const AppHeader(subtitle:'Create and save your own decks'),
 Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
 Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text('Your deck',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold)),Text('${selected.length}/8 cards',style:const TextStyle(fontWeight:FontWeight.bold))]),
 const SizedBox(height:8),Text('Average elixir: ${average.toStringAsFixed(1)}'),
 GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4,childAspectRatio:.8,crossAxisSpacing:6,mainAxisSpacing:6),itemCount:8,itemBuilder:(context,i){if(i>=selected.length)return Container(decoration:BoxDecoration(border:Border.all(color:Theme.of(context).colorScheme.outlineVariant),borderRadius:BorderRadius.circular(12)),child:const Icon(Icons.add));final c=selected[i];final image=cardImage(c);return InkWell(onTap:()=>setState(()=>selected.removeAt(i)),child:Stack(children:[if(image.isNotEmpty)Image.network(image,fit:BoxFit.contain,errorBuilder:(_,__,___)=>const Icon(Icons.broken_image))else const Icon(Icons.style),Align(alignment:Alignment.bottomCenter,child:Container(width:double.infinity,color:Colors.black54,child:Text(c['name']??'',style:const TextStyle(color:Colors.white,fontSize:10),textAlign:TextAlign.center,maxLines:1,overflow:TextOverflow.ellipsis))),const Align(alignment:Alignment.topRight,child:Icon(Icons.close,color:Colors.redAccent,size:18))]));}),
 Row(children:[Expanded(child:OutlinedButton.icon(onPressed:selected.isEmpty?null:()=>setState(()=>selected.clear()),icon:const Icon(Icons.delete_outline),label:const Text('Clear'))),const SizedBox(width:8),Expanded(child:FilledButton.icon(onPressed:selected.length==8?()=>_save():null,icon:const Icon(Icons.save),label:const Text('Save deck')))]),
 ])))),
 Padding(padding:const EdgeInsets.fromLTRB(16,16,16,8),child:Text('Add cards',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold))),
 Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Find a card',border:OutlineInputBorder()),onChanged:(v)=>setState(()=>search=v))),
 if(loading)const LoadingView(label:'Loading card list…'),if(error!=null&&!loading)ErrorView(error:error!,onRetry:load),
 if(!loading&&error==null)Padding(padding:const EdgeInsets.all(12),child:Wrap(spacing:8,runSpacing:8,children:visible.take(100).map((c){final img=cardImage(c);return SizedBox(width:100,child:Card(child:InkWell(onTap:selected.length>=8?null:()=>setState(()=>selected.add(c)),child:Padding(padding:const EdgeInsets.all(8),child:Column(mainAxisSize:MainAxisSize.min,children:[SizedBox(height:74,child:img.isNotEmpty?Image.network(img,fit:BoxFit.contain,errorBuilder:(_,__,___)=>const Icon(Icons.broken_image)):const Icon(Icons.style)),Text(c['name']??'',textAlign:TextAlign.center,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12,fontWeight:FontWeight.bold)),Text('${cardElixir(c)} elixir',style:const TextStyle(fontSize:11))])))));}).toList())),
 Padding(padding:const EdgeInsets.fromLTRB(16,20,16,6),child:Text('Saved decks',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.bold))),
 AnimatedBuilder(animation:AppSettings.instance,builder:(context,_) {final decks=AppSettings.instance.savedDecks;return decks.isEmpty?const Padding(padding:EdgeInsets.all(16),child:Text('No saved decks yet. Create an 8-card deck and save it.')):Column(children:decks.asMap().entries.map((entry){final data=jsonDecode(entry.value) as Map;final names=(data['cards'] as List).join(' • ');return Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:4),child:Card(child:ListTile(title:Text(data['name']??'Saved deck'),subtitle:Text(names,maxLines:2,overflow:TextOverflow.ellipsis),trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()=>AppSettings.instance.removeDeckAt(entry.key)))));}).toList());}),
 ]));}
 Future<void> _save()async{final name='Deck ${DateTime.now().month}/${DateTime.now().day}';final json=jsonEncode({'name':name,'cards':selected.map((c)=>c['name']).toList(),'ids':selected.map((c)=>c['id']).toList(),'savedAt':DateTime.now().toIso8601String()});await AppSettings.instance.saveDeck(json);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Deck saved locally')));}
}
