import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/section_title.dart';
import '../services/app_settings.dart';

class HomeScreen extends StatelessWidget {
 const HomeScreen({super.key});
 @override Widget build(BuildContext context) => SafeArea(child: ListView(padding: const EdgeInsets.only(bottom:24), children:[
   const AppHeader(subtitle:'Your Clash Royale stats companion'),
   Padding(padding:const EdgeInsets.symmetric(horizontal:16), child: Container(padding:const EdgeInsets.all(18), decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF244D8F),Color(0xFF4C89F0)]), borderRadius:BorderRadius.circular(22)), child:const Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
     Text('TRACK YOUR ROYALE',style:TextStyle(color:Colors.white70,fontWeight:FontWeight.w600)),
     SizedBox(height:8), Text('Stats. Cards.\\nDecks. Clans.',style:TextStyle(color:Colors.white,fontSize:26,fontWeight:FontWeight.w900)),
     SizedBox(height:8), Text('Official API data • No demo stats',style:TextStyle(color:Colors.white70)),
   ]))),
   Padding(padding:const EdgeInsets.fromLTRB(16,22,16,10), child: const SectionTitle('Quick access')),
   Padding(padding:const EdgeInsets.symmetric(horizontal:16), child:GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,mainAxisSpacing:10,crossAxisSpacing:10,childAspectRatio:1.45,children:[
     _Tile(icon:Icons.person_search,title:'Player lookup',desc:'Profile & battle log',color:const Color(0xFF3E83F7)),
     _Tile(icon:Icons.shield,title:'Clan lookup',desc:'Clan info & members',color:const Color(0xFF6E55D8)),
     _Tile(icon:Icons.style,title:'Card database',desc:'Browse all cards',color:const Color(0xFF13A88C)),
     _Tile(icon:Icons.view_carousel,title:'Deck builder',desc:'Build & save decks',color:const Color(0xFFE49A33)),
   ])),
   Padding(padding:const EdgeInsets.fromLTRB(16,22,16,8),child:const SectionTitle('Saved favorites')),
   AnimatedBuilder(animation:AppSettings.instance,builder:(context,_) { final favs=AppSettings.instance.favorites; return Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:Card(child:Padding(padding:const EdgeInsets.all(16),child:Text(favs.isEmpty?'No saved tags yet. Save a player or clan from its profile to see it here.':'Saved tags: ${favs.join(', ')}')))); }),
   Padding(padding:const EdgeInsets.fromLTRB(16,22,16,8),child:const SectionTitle('Data transparency')),
   Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:Card(child:Padding(padding:const EdgeInsets.all(16),child:const Text('Live player, clan, battle, and card data is requested through the configured backend. Features that require large community datasets—such as global deck win-rate tracking—are not represented as made-up stats.')))),
 ]));
}
class _Tile extends StatelessWidget {
 const _Tile({required this.icon,required this.title,required this.desc,required this.color});
 final IconData icon;final String title,desc;final Color color;
 @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icon,color:color,size:26),const SizedBox(height:8),Text(title,style:const TextStyle(fontWeight:FontWeight.bold)),Text(desc,style:Theme.of(context).textTheme.bodySmall)])));
}
