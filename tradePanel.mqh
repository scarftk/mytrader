#ifndef __TRADE_PANEL_MQH__
#define __TRADE_PANEL_MQH__
#include <Controls/Dialog.mqh>
#include <Controls/Button.mqh>
#include <Controls/Edit.mqh>
#include <Trade/Trade.mqh>

color RGBc(const int r,const int g,const int b);
extern ulong g_selected_position_ticket;
extern bool  g_selected_is_position;

class CTradePanel : public CAppDialog
  {
private:
   CTrade      m_trade;
   uint        m_deviation_points;

   CEdit       m_timeBar;
   CEdit       m_summaryBar;
   CEdit       m_selectedBar;
   CEdit       m_selectedPctEdit;
   CEdit       m_zeroBar;
   CEdit       m_stoplineBar;

   CEdit       m_slLabel;
   CEdit       m_slEdit;
   CEdit       m_tpLabel;
   CEdit       m_tpEdit;
   CEdit       m_lotEdit;

   CButton     m_btnCloseAll;
   CButton     m_btnCloseSelected;
   CButton     m_btnClose50;
   CButton     m_btnClose80;
   CButton     m_btnCloseSell;
   CButton     m_btnCloseBuy;
   CButton     m_btnCloseProfit;
   CButton     m_btnCloseLoss;
   CButton     m_btnBreakEven;

   CButton     m_btnLot01;
   CButton     m_btnLot02;
   CButton     m_btnLot05;
   CButton     m_btnLot08;

   CButton     m_btnLotMinus;
   CButton     m_btnLotPlus;

   CButton     m_btnSell;
   CButton     m_btnBuy;
   CButton     m_bidBar;
   CButton     m_askBar;

public:
                     CTradePanel(void);
                    ~CTradePanel(void);
   virtual bool      OnEvent(const int id,const long &lparam,const double &dparam,const string &sparam);
   virtual bool      Create(const long chart,const string name,const int subwin,const int x1,const int y1,const int x2,const int y2);
   bool              OnTick(void);
   bool              OnTimer(void);

protected:
   bool              CreateBars(void);
   bool              CreateActionButtons(void);
   bool              CreateStoplineArea(void);
   bool              CreateLotArea(void);
   bool              CreateTradingArea(void);
   bool              CreateButtonStyled(CButton &button,const string suffix,const string text,const int x1,const int y1,const int x2,const int y2,const color back,const color fore,const int font_size=10);
   bool              CreateEditStyled(CEdit &edit,const string suffix,const string text,const int x1,const int y1,const int x2,const int y2,const bool read_only,const color back,const color fore,const int font_size=10,const ENUM_ALIGN_MODE align=ALIGN_CENTER);
   double            ReadLotValue(void) const;
   double            ReadPercentValue(void) const;
   double            NormalizeVolume(const double requested) const;
   bool              CloseByPercentAll(const double pct,const int filter_mode=0);
   bool              PlaceMarket(const ENUM_ORDER_TYPE type);
   bool              ReadStops(const ENUM_ORDER_TYPE type,double &sl,double &tp) const;
   bool              MoveAllToBreakeven(void);
   bool              CloseSelectedByPercent(void);
   bool              OnClickCloseAll(void);
   bool              OnClickCloseSelected(void);
   bool              OnClickClose50(void);
   bool              OnClickClose80(void);
   bool              OnClickCloseSell(void);
   bool              OnClickCloseBuy(void);
   bool              OnClickCloseProfit(void);
   bool              OnClickCloseLoss(void);
   bool              OnClickBreakEven(void);
   bool              OnClickLot01(void);
   bool              OnClickLot02(void);
   bool              OnClickLot05(void);
   bool              OnClickLot08(void);
   bool              OnClickSell(void);
   bool              OnClickBuy(void);
   bool              OnClickBid(void);
   bool              OnClickAsk(void);
   void              UpdateTopInfo(void);
  };




#endif