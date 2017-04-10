//+------------------------------------------------------------------+
//|                                                         baby.mq4 |
//|                                                  Olivier Ghafari |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Olivier Ghafari"
#property link      ""
#property version   "1.00"
#property strict

#define MAGICMA  22021992

//--- input parameters
input double Lots = 0.1;
input bool Stop_Loss = true;
input bool Dynamic_SL = true;
input int TrailingStop=300; 

//---- input parameters de QuivoFx
input int Periods=10;
input double Multiplier=4.0;
input int Correction_Mode=0;
input int PointSize=1;
input int MaxBars=1000;
input bool ShowBreakout=true;
input bool ShowCorrection=true;
input bool ShowPullback=true;
input bool SendAlert=false;
input bool SendEmail=false;
input bool SendPush=false;
input bool OnTrendChange=true;
input bool OnBreakout=true;
input bool OnCorrection=true;
input bool OnPullback=true;

double upSignal = EMPTY_VALUE;
double downSignal = EMPTY_VALUE;
double upTrend = EMPTY_VALUE;
double downTrend = EMPTY_VALUE;
string market = "null";

//upTrend = iCustom(NULL, 0, "Supertrend Plus Free",Periods,Multiplier,Correction_Mode,PointSize,MaxBars,ShowBreakout,ShowCorrection,ShowPullback,SendAlert,SendEmail,SendPush,OnTrendChange,OnBreakout,OnCorrection,OnPullback, 0,1);
//downTrend = iCustom(NULL, 0, "Supertrend Plus Free",Periods,Multiplier,Correction_Mode,PointSize,MaxBars,ShowBreakout,ShowCorrection,ShowPullback,SendAlert,SendEmail,SendPush,OnTrendChange,OnBreakout,OnCorrection,OnPullback, 1,1);
  
  
//+------------------------------------------------------------------+
//| Calculate open positions                                         |
//+------------------------------------------------------------------+
int CalculateCurrentOrders(string symbol){
   int buys=0,sells=0;
//---
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
      if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
        {
         if(OrderType()==OP_BUY)  buys++;
         if(OrderType()==OP_SELL) sells++;
        }
     }
//--- return orders volume
   if(buys>0) return(buys);
   else       return(-sells);
}

void OpenPosition(bool Pos){
   //close old position
   if(CalculateCurrentOrders(Symbol())!=0){
      //close old pos
      for(int i=0;i<OrdersTotal();i++){
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
         if(OrderMagicNumber()!=MAGICMA || OrderSymbol()!=Symbol()) break;
         //--- check order type 
         if(OrderType()==OP_BUY){
            if(!OrderClose(OrderTicket(),OrderLots(),Bid,0,White)){
               Print("OrderClose error ",GetLastError());
            }
            break;
         }else if(OrderType()==OP_SELL){
            if(!OrderClose(OrderTicket(),OrderLots(),Ask,0,White)){
               Print("OrderClose error ",GetLastError());
            }
            break;
         }
      }
   }
   
   //open New
   if (Pos){
      if (Stop_Loss)
         OrderSend(Symbol(),OP_BUY,Lots,Ask,0,Ask-Point*TrailingStop,0,"",MAGICMA,0,Blue);
      else
         OrderSend(Symbol(),OP_BUY,Lots,Ask,0,0,0,"",MAGICMA,0,Blue);
   }else{
      if (Stop_Loss)
         OrderSend(Symbol(),OP_SELL,Lots,Bid,0,Bid+Point*TrailingStop,0,"",MAGICMA,0,Red);
      else
         OrderSend(Symbol(),OP_SELL,Lots,Bid,0,0,0,"",MAGICMA,0,Red);
   }
}
  
//+------------------------------------------------------------------+
//| OnTick function                                                  |
//+------------------------------------------------------------------+
void OnTick(){
      if(Volume[0]>1) return;
//--- check for history and trading
   if(Bars<5 || IsTradeAllowed()==false)
      return;
   
   if (Dynamic_SL){RefreshSL();}
   
   downSignal = iCustom(NULL, 0, "Supertrend Plus Free",Periods,Multiplier,Correction_Mode,PointSize,MaxBars,ShowBreakout,ShowCorrection,ShowPullback,SendAlert,SendEmail,SendPush,OnTrendChange,OnBreakout,OnCorrection,OnPullback, 6,1);
   upSignal = iCustom(NULL, 0, "Supertrend Plus Free",Periods,Multiplier,Correction_Mode,PointSize,MaxBars,ShowBreakout,ShowCorrection,ShowPullback,SendAlert,SendEmail,SendPush,OnTrendChange,OnBreakout,OnCorrection,OnPullback, 5,1);
   if (downSignal!=EMPTY_VALUE){
         Print("Market DEVIENT BEAR");
         OpenPosition(false);
   }else if (upSignal!=EMPTY_VALUE){
         Print("Market DEVIENT BULL");
         OpenPosition(true);
   }

}

//Dynamic Stop loss
void RefreshSL(){
   
//--- modifies Stop Loss price for buy order 
   if(TrailingStop>0) { 
      if (OrderSelect(0,SELECT_BY_POS)==true){ 

         if (OrderType()==OP_BUY){
            if(OrderStopLoss()<Ask-Point*TrailingStop)  { 
                  bool res=OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Ask-Point*TrailingStop,Digits),OrderTakeProfit(),0,Blue); 
                  if(!res) 
                     Print("Error in OrderModify. Error code=",GetLastError()); 
                  else 
                     Print("Order modified successfully."); 
            } 
         }else {
            if(OrderStopLoss()>Bid+Point*TrailingStop)  { 
                  bool res=OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Bid+Point*TrailingStop,Digits),OrderTakeProfit(),0,Blue); 
                  if(!res) 
                     Print("Error in OrderModify. Error code=",GetLastError()); 
                  else 
                     Print("Order modified successfully."); 
             } 
         }
     }
   }
}