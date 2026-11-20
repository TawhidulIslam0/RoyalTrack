import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';
import '../widgets/app_header.dart';
import '../widgets/async_state.dart';

class CardsScreen extends StatefulWidget {const CardsScreen({super.key});@override State<CardsScreen> createState()=>_CardsScreenState();}
class _CardsScreenState extends State<CardsScreen>{
 List<dynamic> cards=[];bool loading=false;Object? error;String query='',filter='All';
 Future<void> load()async{setState(()=>loading=true);try{final data=await ApiService.instance.cards();if(!mounted)return;setState(()=>cards=List<dynamic>.from(data['items']??[]));error=null;}catch(e){if(mounted)setState(()=>error=e);}finally{if(mounted)setState(()=>loading=false);}}
 @override void initState(){super.initState();load();}
 @override Widget build(BuildContext context){final filtered=cards.where((c){final name=(c['name']??'').toString().toLowerCase();final q=query.toLowerCase();return name.contains(q)&&(filter=='All'||rarity(c)==filter);}).toList();return SafeArea(child:Column(children:[
 const AppHeader(subtitle:'Search and browse the official card catalog'),
 Padding(padding:const EdgeInsets.fromLTRB(16,0,16,8),child:TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Search cards',border:OutlineInputBorder()),onChanged:(v)=>setState(()=>query=v)),
 ),
 SizedBox(height:44,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:12),children:['All','Common','Rare','Epic','Legendary','Champion'].map((f)=>Padding(padding:const EdgeInsets.symmetric(horizontal:4),child:ChoiceChip(label:Text(f),selected:filter==f,onSelected:(_)=>setState(()=>filter=f)))).toList())),
 if(loading)const Expanded(child:LoadingView(label:'Loading cards…')),
 if(error!=null&&!loading)Expanded(child:ErrorView(error:error!,onRetry:load)),
 if(!loading&&error==null)Expanded(child:filtered.isEmpty?const EmptyView(message:'No matching cards found.'):GridView.builder(padding:const EdgeInsets.all(12),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,childAspectRatio:0.82,crossAxisSpacing:10,mainAxisSpacing:10),itemCount:filtered.length,itemBuilder:(context,i){final c=filtered[i];final img=cardImage(c);return Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[Expanded(child:img.isEmpty?const Icon(Icons.image_not_supported):Image.network(img,fit:BoxFit.contain,errorBuilder:(_,__,___)=>const Icon(Icons.broken_image))),Text(safeString(c['name']),style:const TextStyle(fontWeight:FontWeight.bold),textAlign:TextAlign.center,maxLines:2),const SizedBox(height:4),Row(mainAxisAlignment:MainAxisAlignment.center,children:[if(c['elixirCost']!=null)Text('${c['elixirCost']} elixir • '),Text(rarity(c))])])));})),
 ]));}
}
