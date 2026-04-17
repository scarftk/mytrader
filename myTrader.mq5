//+------------------------------------------------------------------+
//|                                                     myTrader.mq5 |
//|                                  Copyright 2026, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#property strict
#property version "1.00"

#include "tradePanel.mq5"
#include <Controls/ListView.mqh>

input int InpPanelWidth = 330;
input int InpPanelHeight = 500;
input int InpLeftOffset = 8;
input int InpTopOffset = 28;
input ulong InpMagic = 20260411;
input uint InpDeviationPts = 20;

CTradePanel ExtPanel;
ulong g_selected_position_ticket=0;
bool  g_selected_is_position=false;
class COrderListDialog : public CAppDialog
  {
private:
   CListView m_list;
   CTrade    m_trade;

public:
  virtual bool OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam);
   virtual bool Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2)
     {
      if(!CAppDialog::Create(chart,name,subwin,x1,y1,x2,y2))
         return(false);

      int left=6;
      int top=6;
      int right=ClientAreaWidth()-6;
      int bottom=ClientAreaHeight()-6;

      m_list.TotalView(10);
      if(!m_list.Create(m_chart_id,m_name+"_List",m_subwin,left,top,right,bottom))
         return(false);
      if(!Add(m_list))
         return(false);

      m_trade.SetDeviationInPoints((int)InpDeviationPts);
      Refresh();
      return(true);
     }

   void Refresh(void)
     {
      m_list.ItemsClear();
      int shown=0;

      for(int i=PositionsTotal()-1; i>=0; --i)
        {
         ulong ticket=PositionGetTicket(i);
         if(ticket==0 || !PositionSelectByTicket(ticket))
            continue;

         string side=((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)?"多":"空";
         double vol=PositionGetDouble(POSITION_VOLUME);
        double open_price=PositionGetDouble(POSITION_PRICE_OPEN);
        double profit=PositionGetDouble(POSITION_PROFIT);
        string profit_text=(profit>=0.0?"+":"")+DoubleToString(profit,2);
        string row=StringFormat("%s %.2f %s %s",side,vol,DoubleToString(open_price,_Digits),profit_text);
         m_list.ItemAdd(row,(long)ticket);
         shown++;
        }

      for(int j=OrdersTotal()-1; j>=0; --j)
        {
         ulong ticket=OrderGetTicket(j);
         if(ticket==0 || !OrderSelect(ticket))
            continue;

         string sym=OrderGetString(ORDER_SYMBOL);
         ENUM_ORDER_TYPE ot=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
         string otype="挂单";
         if(ot==ORDER_TYPE_BUY_LIMIT || ot==ORDER_TYPE_BUY_STOP || ot==ORDER_TYPE_BUY_STOP_LIMIT)
            otype="买挂";
         else if(ot==ORDER_TYPE_SELL_LIMIT || ot==ORDER_TYPE_SELL_STOP || ot==ORDER_TYPE_SELL_STOP_LIMIT)
            otype="卖挂";
         double vol=OrderGetDouble(ORDER_VOLUME_CURRENT);
         string row=StringFormat("挂单 #%I64u  %s  %s  %.2f   x",ticket,sym,otype,vol);
         m_list.ItemAdd(row,-(long)ticket);
         shown++;
        }

      if(shown==0)
         m_list.ItemAdd("当前无持仓/挂单",0);
     }

protected:
   void OnListChange(void)
     {
      long value=m_list.Value();
      if(value==0)
         return;

      if(value>0)
        {
      g_selected_position_ticket=(ulong)value;
      g_selected_is_position=true;
      PrintFormat("[ListSelect] type=position ticket=%I64u",g_selected_position_ticket);
        }
      else
        {
      g_selected_position_ticket=(ulong)(-value);
      g_selected_is_position=false;
      PrintFormat("[ListSelect] type=order ticket=%I64u",g_selected_position_ticket);
        }
     }
  };

EVENT_MAP_BEGIN(COrderListDialog)
   ON_EVENT(ON_CHANGE,m_list,OnListChange)
EVENT_MAP_END(CAppDialog)

COrderListDialog OrderList;

int OnInit()
{
  //--- create timer

  

  // int x1 = InpLeftOffset;
  // int x2 = x1 + InpPanelWidth;
  int chart_width = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0);

  int x2 = chart_width - InpLeftOffset;
  int x1 = x2 - InpPanelWidth;
  if (x1 < 0)
  {
    x1 = 0;
    x2 = chart_width;
  }

  int y1 = InpTopOffset;
  int y2 = y1 + InpPanelHeight;

  //  ExtPanel.SetTradeConfig(InpMagic,InpDeviationPts);
  if (!OrderList.Create(0, "orderList", 0, 8, 28, 320, 260))
    return (INIT_FAILED);

  if (!ExtPanel.Create(0, "tradePanel", 0, x1, y1, x2, y2))
    return (INIT_FAILED);

  OrderList.Run();
  ExtPanel.Run();
  ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
  EventSetTimer(1);
  //---
  return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
  //--- destroy timer
  EventKillTimer();
  OrderList.Destroy(reason);
  ExtPanel.Destroy(reason);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
  ExtPanel.OnTick();
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
  //---
  ExtPanel.OnTimer();
  OrderList.Refresh();
}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
  if(id>=CHARTEVENT_CUSTOM)
    {
     string list_prefix=OrderList.Name();
     string panel_prefix=ExtPanel.Name();
     if(StringFind(sparam,list_prefix)==0)
       {
        OrderList.ChartEvent(id,lparam,dparam,sparam);
        return;
       }
     if(StringFind(sparam,panel_prefix)==0)
       {
        ExtPanel.ChartEvent(id,lparam,dparam,sparam);
        return;
       }
    }

  if(id==CHARTEVENT_MOUSE_MOVE)
    {
     int mx=(int)lparam;
     int my=(int)dparam;
     if(OrderList.Contains(mx,my))
       {
        OrderList.ChartEvent(id,lparam,dparam,sparam);
        return;
       }
     if(ExtPanel.Contains(mx,my))
       {
        ExtPanel.ChartEvent(id,lparam,dparam,sparam);
        return;
       }
    }

  if(id==CHARTEVENT_OBJECT_CLICK)
    {
     string list_prefix=OrderList.Name();
     if(StringFind(sparam,list_prefix)==0)
       {
        OrderList.ChartEvent(id,lparam,dparam,sparam);
        return;
       }
    }

  OrderList.ChartEvent(id,lparam,dparam,sparam);
  ExtPanel.ChartEvent(id,lparam,dparam,sparam);
}
//+------------------------------------------------------------------+
