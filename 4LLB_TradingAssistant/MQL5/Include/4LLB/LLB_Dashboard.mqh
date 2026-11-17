//+------------------------------------------------------------------+
//| LLB_Dashboard.mqh                                                |
//| Display-only chart panel (R-DSH-01..07). It owns no trading      |
//| buttons and has no access to the ExecutionManager: it cannot     |
//| send orders. Clicking the panel only collapses/expands it.       |
//+------------------------------------------------------------------+
#ifndef LLB_DASHBOARD_MQH
#define LLB_DASHBOARD_MQH

#include "LLB_Defines.mqh"
#include "LLB_Utils.mqh"

#define LLB_DASH_LINE_H    14
#define LLB_DASH_COL_W     380
#define LLB_DASH_MAX_CHARS 62
#define LLB_DASH_MARGIN    6

enum ENUM_LLB_DASH_POS
  {
   LLB_DASH_TOP_LEFT     = 0,  // Top left
   LLB_DASH_TOP_RIGHT    = 1,  // Top right
   LLB_DASH_BOTTOM_LEFT  = 2,  // Bottom left
   LLB_DASH_BOTTOM_RIGHT = 3   // Bottom right
  };

class CLLBDashboard
  {
private:
   bool              m_enabled;
   bool              m_collapsed;
   int               m_pos;
   string            m_prefix;
   int               m_drawn;     // number of line labels currently on the chart

   void              Label(const string name,const int x,const int y,const string text,const color clr)
     {
      if(ObjectFind(0,name)<0)
        {
         if(!ObjectCreate(0,name,OBJ_LABEL,0,0,0))
            return;
         ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
         ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
         ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
         ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
         ObjectSetInteger(0,name,OBJPROP_BACK,false);
         ObjectSetString(0,name,OBJPROP_FONT,"Consolas");
         ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
        }
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
      ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
      ObjectSetString(0,name,OBJPROP_TEXT,LLB_Truncate(text,LLB_DASH_MAX_CHARS));
     }

   void              Background(const int x,const int y,const int width,const int height)
     {
      string name=m_prefix+"bg";
      if(ObjectFind(0,name)<0)
        {
         if(!ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0))
            return;
         ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
         ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
         ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
         ObjectSetInteger(0,name,OBJPROP_BACK,true);         // candles stay visible above the panel background
         ObjectSetInteger(0,name,OBJPROP_BGCOLOR,C'20,24,32');
         ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
         ObjectSetInteger(0,name,OBJPROP_COLOR,C'70,80,100');
        }
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
      ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(0,name,OBJPROP_XSIZE,width);
      ObjectSetInteger(0,name,OBJPROP_YSIZE,height);
     }

public:
                     CLLBDashboard(void)
     {
      m_enabled=false;
      m_collapsed=false;
      m_pos=LLB_DASH_TOP_LEFT;
      m_prefix="4LLB_DASH_";
      m_drawn=0;
     }

   void              Init(const bool enabled,const string prefix,const int position,const bool collapsed)
     {
      m_enabled=enabled;
      m_prefix=prefix;
      m_pos=position;
      m_collapsed=collapsed;
     }

   void              Deinit(void)
     {
      ObjectsDeleteAll(0,m_prefix);
      ChartRedraw(0);
     }

   //--- click on any panel object toggles collapsed / expanded (display only)
   bool              OnClick(const string objectName)
     {
      if(!m_enabled || StringFind(objectName,m_prefix)!=0)
         return false;
      m_collapsed=!m_collapsed;
      return true;
     }

   //--- header line + one column of lines per enabled symbol
   void              Render(const string header,const string &lines[],const int &colOf[],const color &colors[])
     {
      if(!m_enabled)
         return;
      int n=ArraySize(lines);
      int cols=1;
      int perCol[];
      ArrayResize(perCol,LLB_MAX_SYMBOLS);
      ArrayInitialize(perCol,0);
      for(int i=0; i<n; i++)
        {
         int c=colOf[i];
         if(c<0 || c>=LLB_MAX_SYMBOLS)
            continue;
         if(c+1>cols)
            cols=c+1;
         perCol[c]++;
        }
      int maxLines=0;
      for(int c=0; c<cols; c++)
         if(perCol[c]>maxLines)
            maxLines=perCol[c];
      if(m_collapsed)
         maxLines=0;
      int width=MathMax(cols*LLB_DASH_COL_W,LLB_DASH_COL_W)+12;
      int height=(maxLines+1)*LLB_DASH_LINE_H+10;
      //--- panel origin from the chosen chart corner
      int chartW=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS);
      int chartH=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0);
      int x0=LLB_DASH_MARGIN;
      int y0=LLB_DASH_MARGIN+14;                            // below the chart title line
      if(m_pos==LLB_DASH_TOP_RIGHT || m_pos==LLB_DASH_BOTTOM_RIGHT)
         x0=MathMax(LLB_DASH_MARGIN,chartW-width-LLB_DASH_MARGIN-60);   // keep clear of the price scale
      if(m_pos==LLB_DASH_BOTTOM_LEFT || m_pos==LLB_DASH_BOTTOM_RIGHT)
         y0=MathMax(LLB_DASH_MARGIN,chartH-height-LLB_DASH_MARGIN-20);  // keep clear of the time scale
      //--- remove labels that are no longer used
      int needed=m_collapsed ? 0 : n;
      if(needed<m_drawn)
        {
         ObjectsDeleteAll(0,m_prefix+"c");
         m_drawn=0;
        }
      Background(x0,y0,width,height);
      Label(m_prefix+"hdr",x0+6,y0+5,header+(m_collapsed ? "  [+]" : "  [-]"),clrGold);
      if(!m_collapsed)
        {
         int row[];
         ArrayResize(row,LLB_MAX_SYMBOLS);
         ArrayInitialize(row,0);
         for(int i=0; i<n; i++)
           {
            int c=colOf[i];
            if(c<0 || c>=LLB_MAX_SYMBOLS)
               continue;
            int y=y0+5+LLB_DASH_LINE_H*(row[c]+1);
            Label(m_prefix+"c"+IntegerToString(c)+"_"+IntegerToString(row[c]),x0+6+c*LLB_DASH_COL_W,y,lines[i],colors[i]);
            row[c]++;
           }
        }
      m_drawn=needed;
      ChartRedraw(0);
     }
  };

#endif
//+------------------------------------------------------------------+
