#include "tradePanel.mqh"

color RGBc(const int r,const int g,const int b)
  {
   return((color)((b<<16) | (g<<8) | r));
  }

CTradePanel::CTradePanel(void)
  {
   m_trade.SetDeviationInPoints(20);
   m_deviation_points=20;
  }

CTradePanel::~CTradePanel(void)
  {
  }

EVENT_MAP_BEGIN(CTradePanel)
   ON_EVENT(ON_CLICK,m_btnCloseAll,OnClickCloseAll)
   ON_EVENT(ON_CLICK,m_btnCloseSelected,OnClickCloseSelected)
   ON_EVENT(ON_CLICK,m_btnClose50,OnClickClose50)
   ON_EVENT(ON_CLICK,m_btnClose80,OnClickClose80)
   ON_EVENT(ON_CLICK,m_btnCloseSell,OnClickCloseSell)
   ON_EVENT(ON_CLICK,m_btnCloseBuy,OnClickCloseBuy)
   ON_EVENT(ON_CLICK,m_btnCloseProfit,OnClickCloseProfit)
   ON_EVENT(ON_CLICK,m_btnCloseLoss,OnClickCloseLoss)
   ON_EVENT(ON_CLICK,m_btnBreakEven,OnClickBreakEven)
   ON_EVENT(ON_CLICK,m_btnLot01,OnClickLot01)
   ON_EVENT(ON_CLICK,m_btnLot02,OnClickLot02)
   ON_EVENT(ON_CLICK,m_btnLot05,OnClickLot05)
   ON_EVENT(ON_CLICK,m_btnLot08,OnClickLot08)
   ON_EVENT(ON_CLICK,m_btnSell,OnClickSell)
   ON_EVENT(ON_CLICK,m_btnBuy,OnClickBuy)
   ON_EVENT(ON_CLICK,m_bidBar,OnClickBid)
   ON_EVENT(ON_CLICK,m_askBar,OnClickAsk)
EVENT_MAP_END(CAppDialog)

double CTradePanel::NormalizeVolume(const double requested) const
  {
   double min_lot=0.0,max_lot=0.0,step=0.0;
   SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN,min_lot);
   SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX,max_lot);
   SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP,step);

   if(step<=0.0)
      step=0.01;
   if(min_lot<=0.0)
      min_lot=step;
   if(max_lot<min_lot)
      max_lot=min_lot;

   double lot=requested;
   if(lot<min_lot)
      lot=min_lot;
   if(lot>max_lot)
      lot=max_lot;

   lot=min_lot+MathFloor((lot-min_lot)/step)*step;
   if(lot<min_lot)
      lot=min_lot;
   return(NormalizeDouble(lot,2));
  }

double CTradePanel::ReadLotValue(void) const
  {
   double lot=StringToDouble(m_lotEdit.Text());
   if(lot<=0.0)
      lot=0.01;
   return(NormalizeVolume(lot));
  }

double CTradePanel::ReadPercentValue(void) const
  {
   double pct=StringToDouble(m_selectedPctEdit.Text());
   if(pct<=0.0)
      pct=50.0;
   if(pct>100.0)
      pct=100.0;
   return(pct);
  }

bool CTradePanel::ReadStops(const ENUM_ORDER_TYPE type,double &sl,double &tp) const
  {
   sl=StringToDouble(m_slEdit.Text());
   tp=StringToDouble(m_tpEdit.Text());
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);

   if(sl<=0.0)
      sl=0.0;
   if(tp<=0.0)
      tp=0.0;

   if(type==ORDER_TYPE_BUY)
     {
      if(sl>0.0 && sl>=ask)
         sl=0.0;
      if(tp>0.0 && tp<=ask)
         tp=0.0;
     }
   else
     {
      if(sl>0.0 && sl<=bid)
         sl=0.0;
      if(tp>0.0 && tp>=bid)
         tp=0.0;
     }
   return(true);
  }

bool CTradePanel::PlaceMarket(const ENUM_ORDER_TYPE type)
  {
   double lot=ReadLotValue();
   double sl=0.0,tp=0.0;
   ReadStops(type,sl,tp);

   bool ok=false;
   if(type==ORDER_TYPE_BUY)
      ok=m_trade.Buy(lot,_Symbol,0.0,sl,tp);
   else
      ok=m_trade.Sell(lot,_Symbol,0.0,sl,tp);

   if(!ok)
      Print("PlaceMarket failed, retcode=",m_trade.ResultRetcode());
   return(ok);
  }

bool CTradePanel::IsPositionMatched(const ENUM_POSITION_TYPE ptype,const double profit,const EPositionFilter filter) const
  {
   if(filter==FILTER_SELL && ptype!=POSITION_TYPE_SELL)
      return(false);
   if(filter==FILTER_BUY && ptype!=POSITION_TYPE_BUY)
      return(false);
   if(filter==FILTER_PROFIT && profit<=0.0)
      return(false);
   if(filter==FILTER_LOSS && profit>=0.0)
      return(false);
   return(true);
  }

bool CTradePanel::ClosePositionByPercent(const ulong ticket,const double volume,const double pct)
  {
   const double close_volume=NormalizeVolume(volume*pct/100.0);
   if(close_volume>=volume-0.0000001)
      return(m_trade.PositionClose(ticket));
   return(m_trade.PositionClosePartial(ticket,close_volume));
  }

bool CTradePanel::CloseByPercentAll(const double pct,const EPositionFilter filter)
  {
   bool ok=true;
   for(int i=PositionsTotal()-1; i>=0; --i)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;

      ENUM_POSITION_TYPE ptype=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double profit=PositionGetDouble(POSITION_PROFIT);
      if(!IsPositionMatched(ptype,profit,filter))
         continue;

      double volume=PositionGetDouble(POSITION_VOLUME);
      bool one_ok=ClosePositionByPercent(ticket,volume,pct);

      if(!one_ok)
        {
         ok=false;
         Print("CloseByPercentAll failed, ticket=",ticket," retcode=",m_trade.ResultRetcode());
        }
     }
   return(ok);
  }

bool CTradePanel::CloseSelectedByPercent(void)
  {
    PrintFormat("[CloseSelected] enter is_position=%d ticket=%I64u pct=%.2f",(int)g_selected_is_position,g_selected_position_ticket,ReadPercentValue());
   if(!g_selected_is_position || g_selected_position_ticket==0)
     {
      Print("No selected position in order list");
      return(false);
     }
   if(!PositionSelectByTicket(g_selected_position_ticket))
      return(false);

   double pct=ReadPercentValue();
   double volume=PositionGetDouble(POSITION_VOLUME);
   double close_volume=NormalizeVolume(volume*pct/100.0);
   bool ok=ClosePositionByPercent(g_selected_position_ticket,volume,pct);

   if(!ok)
      Print("CloseSelectedByPercent failed, ticket=",g_selected_position_ticket," retcode=",m_trade.ResultRetcode());
   else
      PrintFormat("[CloseSelected] success ticket=%I64u close_volume=%.2f",g_selected_position_ticket,close_volume);
   return(ok);
  }

bool CTradePanel::MoveAllToBreakeven(void)
  {
   if(!g_selected_is_position || g_selected_position_ticket==0)
     {
      Print("No selected position for breakeven");
      return(false);
     }

   if(!PositionSelectByTicket(g_selected_position_ticket))
     {
      Print("Selected position no longer exists, ticket=",g_selected_position_ticket);
      return(false);
     }

   double open_price=PositionGetDouble(POSITION_PRICE_OPEN);
   double tp=PositionGetDouble(POSITION_TP);
   bool ok=m_trade.PositionModify(g_selected_position_ticket,open_price,tp);
   if(!ok)
      Print("MoveAllToBreakeven failed, ticket=",g_selected_position_ticket," retcode=",m_trade.ResultRetcode());
   return(ok);
  }

bool CTradePanel::OnClickCloseAll(void)      { return(CloseByPercentAll(100.0,FILTER_ALL)); }
bool CTradePanel::OnClickCloseSelected(void)
   {
    Print("[CloseSelected] button click");
    return(CloseSelectedByPercent());
   }
bool CTradePanel::OnClickClose50(void)       { return(CloseByPercentAll(50.0,FILTER_ALL)); }
bool CTradePanel::OnClickClose80(void)       { return(CloseByPercentAll(80.0,FILTER_ALL)); }
bool CTradePanel::OnClickCloseSell(void)     { return(CloseByPercentAll(100.0,FILTER_SELL)); }
bool CTradePanel::OnClickCloseBuy(void)      { return(CloseByPercentAll(100.0,FILTER_BUY)); }
bool CTradePanel::OnClickCloseProfit(void)   { return(CloseByPercentAll(100.0,FILTER_PROFIT)); }
bool CTradePanel::OnClickCloseLoss(void)     { return(CloseByPercentAll(100.0,FILTER_LOSS)); }
bool CTradePanel::OnClickBreakEven(void)     { return(MoveAllToBreakeven()); }
bool CTradePanel::OnClickLot01(void)         { return(m_lotEdit.Text("0.1")); }
bool CTradePanel::OnClickLot02(void)         { return(m_lotEdit.Text("0.2")); }
bool CTradePanel::OnClickLot05(void)         { return(m_lotEdit.Text("0.5")); }
bool CTradePanel::OnClickLot08(void)         { return(m_lotEdit.Text("0.8")); }
bool CTradePanel::OnClickSell(void)          { return(PlaceMarket(ORDER_TYPE_SELL)); }
bool CTradePanel::OnClickBuy(void)           { return(PlaceMarket(ORDER_TYPE_BUY)); }
bool CTradePanel::OnClickBid(void)           { return(PlaceMarket(ORDER_TYPE_SELL)); }
bool CTradePanel::OnClickAsk(void)           { return(PlaceMarket(ORDER_TYPE_BUY)); }

bool CTradePanel::Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2)
  {
   if(!CAppDialog::Create(chart,name,subwin,x1,y1,x2,y2))
     {
      Print("Failed to create panel!");
      return(false);
     }

   if(!CreateBars())
      return(false);
   if(!CreateActionButtons())
      return(false);
   if(!CreateStoplineArea())
      return(false);
   if(!CreateLotArea())
      return(false);
   if(!CreateTradingArea())
      return(false);

   UpdateTopInfo();
   return(true);
  }

bool CTradePanel::CreateBars(void)
  {
   int left=8;
   int right=ClientAreaWidth()-8;
   int y=8;

   if(!CreateEditStyled(m_timeBar,"_Time","",left,y,right,y+22,true,RGBc(72,72,72),clrWhite,12,ALIGN_CENTER))
      return(false);
   y+=26;

   if(!CreateButtonStyled(m_btnCloseAll,"_CloseAll","一键平仓  0.00",left,y,right,y+24,RGBc(214,184,52),clrBlack,10))
      return(false);
   y+=30;

   int full=right-left;
   int gap=4;
   int half=(full-gap)/2;
   int unit_w=42;

   if(!CreateButtonStyled(m_btnCloseSelected,"_CloseSelected","订单单独减仓",left,y,left+half,y+26,RGBc(214,184,52),clrBlack,11))
      return(false);
   if(!CreateEditStyled(m_selectedPctEdit,"_SelectedPct","50",left+half+gap,y,right-unit_w-gap,y+26,false,RGBc(96,96,96),RGBc(124,195,64),22,ALIGN_CENTER))
      return(false);
   if(!CreateEditStyled(m_selectedBar,"_SelectedUnit","%",right-unit_w,y,right,y+26,true,RGBc(96,96,96),clrWhite,14,ALIGN_CENTER))
      return(false);

   return(true);
  }

bool CTradePanel::CreateActionButtons(void)
  {
   int left=8;
   int right=ClientAreaWidth()-8;
   int full=right-left;
   int gap=4;
   int y=96;
   int h=34;
   int col=(full-gap)/2;

   if(!CreateButtonStyled(m_btnClose50,"_Close50","平仓50%",left,y,left+col,y+h,RGBc(238,238,238),clrBlack,16))
      return(false);
   if(!CreateButtonStyled(m_btnClose80,"_Close80","平仓80%",left+col+gap,y,right,y+h,RGBc(238,238,238),clrBlack,16))
      return(false);
   y+=h+4;

   if(!CreateButtonStyled(m_btnCloseSell,"_CloseSell","平空",left,y,left+col,y+h,RGBc(238,238,238),clrBlack,16))
      return(false);
   if(!CreateButtonStyled(m_btnCloseBuy,"_CloseBuy","平多",left+col+gap,y,right,y+h,RGBc(238,238,238),clrBlack,16))
      return(false);
   y+=h+4;

   if(!CreateButtonStyled(m_btnCloseProfit,"_CloseProfit","平盈",left,y,left+col,y+h,RGBc(238,238,238),clrBlack,16))
      return(false);
   if(!CreateButtonStyled(m_btnCloseLoss,"_CloseLoss","平亏",left+col+gap,y,right,y+h,RGBc(238,238,238),clrBlack,16))
      return(false);
   y+=h+4;

   if(!CreateButtonStyled(m_btnBreakEven,"_BE","一键保本",left,y,left+col,y+h,RGBc(238,238,238),clrBlack,16))
      return(false);
   if(!CreateEditStyled(m_zeroBar,"_Zero","0",left+col+gap,y,right,y+h,true,RGBc(90,90,90),RGBc(124,195,64),24,ALIGN_CENTER))
      return(false);

   return(true);
  }

bool CTradePanel::CreateStoplineArea(void)
  {
   int left=8;
   int right=ClientAreaWidth()-8;
   int full=right-left;
   int gap=4;
   int y=248;
   int h=30;

   if(!CreateEditStyled(m_stoplineBar,"_Stopline","止损线 0.00",left,y,right,y+h,true,RGBc(238,238,238),clrBlack,16,ALIGN_CENTER))
      return(false);
   y+=h+4;

   int label_w=26;
   int val_w=(full-2*label_w-gap*3)/2;
   if(!CreateEditStyled(m_slLabel,"_SLLabel","sl",left,y,left+label_w,y+h,true,RGBc(96,96,96),clrWhite,12,ALIGN_CENTER))
      return(false);
   if(!CreateEditStyled(m_slEdit,"_SLValue","0",left+label_w+gap,y,left+label_w+gap+val_w,y+h,false,RGBc(82,82,82),RGBc(124,195,64),22,ALIGN_CENTER))
      return(false);

   int tp_l=left+label_w+gap+val_w+gap;
   if(!CreateEditStyled(m_tpLabel,"_TPLabel","tp",tp_l,y,tp_l+label_w,y+h,true,RGBc(96,96,96),clrWhite,12,ALIGN_CENTER))
      return(false);
   if(!CreateEditStyled(m_tpEdit,"_TPValue","0",tp_l+label_w+gap,y,right,y+h,false,RGBc(82,82,82),RGBc(124,195,64),22,ALIGN_CENTER))
      return(false);

   return(true);
  }

bool CTradePanel::CreateLotArea(void)
  {
   int left=8;
   int right=ClientAreaWidth()-8;
   int full=right-left;
   int gap=2;
   int y=316;
   int h=24;
   int w=(full-gap*3)/4;

   if(!CreateButtonStyled(m_btnLot01,"_Lot01","0.1",left,y,left+w,y+h,RGBc(96,96,96),clrWhite,15))
      return(false);
   if(!CreateButtonStyled(m_btnLot02,"_Lot02","0.2",left+w+gap,y,left+2*w+gap,y+h,RGBc(96,96,96),clrWhite,15))
      return(false);
   if(!CreateButtonStyled(m_btnLot05,"_Lot05","0.5",left+2*w+gap*2,y,left+3*w+gap*2,y+h,RGBc(96,96,96),clrWhite,15))
      return(false);
   if(!CreateButtonStyled(m_btnLot08,"_Lot08","0.8",left+3*w+gap*3,y,right,y+h,RGBc(96,96,96),clrWhite,15))
      return(false);

   return(true);
  }

bool CTradePanel::CreateTradingArea(void)
  {
   int left=8;
   int right=ClientAreaWidth()-8;
   int full=right-left;
   int gap=2;
   int y=346;
   int h=28;
   int w1=(full-2*gap)*3/10;
   int w2=(full-2*gap)*4/10;

   if(!CreateButtonStyled(m_btnSell,"_SellTop","空",left,y,left+w1,y+h,RGBc(14,142,20),clrWhite,20))
      return(false);
   if(!CreateEditStyled(m_lotEdit,"_LotEdit","2",left+w1+gap,y,left+w1+gap+w2,y+h,false,RGBc(242,242,242),RGBc(180,80,100),28,ALIGN_CENTER))
      return(false);
   if(!CreateButtonStyled(m_btnBuy,"_BuyTop","多",left+w1+gap+w2+gap,y,right,y+h,RGBc(183,34,34),clrWhite,20))
      return(false);
   y+=h+2;

   int full2=right-left;
   int half2=(full2-gap)/2;
   if(!CreateButtonStyled(m_bidBar,"_Bid","0.00",left,y,left+half2,y+h+8,RGBc(14,142,20),clrWhite,24))
      return(false);
   if(!CreateButtonStyled(m_askBar,"_Ask","0.00",left+half2+gap,y,right,y+h+8,RGBc(183,34,34),clrWhite,24))
      return(false);

   return(true);
  }

bool CTradePanel::CreateEditStyled(CEdit &edit,const string suffix,const string text,const int x1,const int y1,const int x2,const int y2,const bool read_only,const color back,const color fore,const int font_size,const ENUM_ALIGN_MODE align)
  {
   if(!edit.Create(m_chart_id,m_name+suffix,m_subwin,x1,y1,x2,y2))
      return(false);
   if(!edit.ReadOnly(read_only))
      return(false);
   if(!edit.TextAlign(align))
      return(false);
   if(!edit.Text(text))
      return(false);
   if(!edit.ColorBackground(back))
      return(false);
   if(!edit.ColorBorder(RGBc(18,18,18)))
      return(false);
   if(!edit.Color(fore))
      return(false);
   if(!edit.FontSize(12))
      return(false);
   if(!Add(edit))
      return(false);
   return(true);
  }

bool CTradePanel::CreateButtonStyled(CButton &button,const string suffix,const string text,const int x1,const int y1,const int x2,const int y2,const color back,const color fore,const int font_size)
  {
   if(!button.Create(m_chart_id,m_name+suffix,m_subwin,x1,y1,x2,y2))
      return(false);
   if(!button.Text(text))
      return(false);
   if(!button.ColorBackground(back))
      return(false);
   if(!button.ColorBorder(RGBc(18,18,18)))
      return(false);
   if(!button.Color(fore))
      return(false);
   if(!button.FontSize(12))
      return(false);
   if(!Add(button))
      return(false);
   return(true);
  }

void CTradePanel::UpdateTopInfo(void)
  {
   datetime now_local=TimeLocal();
   MqlDateTime dt;
   TimeToStruct(now_local,dt);
   string week_cn[7] = {"周日","周一","周二","周三","周四","周五","周六"};
   m_timeBar.Text(StringFormat("%04d.%02d.%02d %02d:%02d:%02d %s",dt.year,dt.mon,dt.day,dt.hour,dt.min,dt.sec,week_cn[dt.day_of_week]));

   double total_profit=0.0;
   for(int i=0;i<PositionsTotal();i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol)
         continue;
      total_profit+=PositionGetDouble(POSITION_PROFIT);
     }

   m_btnCloseAll.Text(StringFormat("一键平仓  %.2f",total_profit));

   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   m_bidBar.Text(DoubleToString(bid,_Digits));
   m_askBar.Text(DoubleToString(ask,_Digits));
  }

bool CTradePanel::OnTimer(void)
  {
   UpdateTopInfo();
   return(true);
  }

bool CTradePanel::OnTick(void)
   {
    UpdateTopInfo();
    return(true);
   }
