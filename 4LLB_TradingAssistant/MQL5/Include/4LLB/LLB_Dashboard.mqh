//+------------------------------------------------------------------+
//| LLB_Dashboard.mqh                                                |
//| Display-only chart panel (R-DSH-01..07). It owns no buttons and  |
//| has no access to the ExecutionManager: it cannot send orders.    |
//+------------------------------------------------------------------+
#ifndef LLB_DASHBOARD_MQH
#define LLB_DASHBOARD_MQH

#include "LLB_Defines.mqh"
#include "LLB_Utils.mqh"

#define LLB_DASH_LINE_H   14
#define LLB_DASH_COL_W    390
#define LLB_DASH_MAX_CHARS 62

class CLLBDashboard
  {
private:
   bool              m_enabled;
   string            m_prefix;
   int               m_cols;
   int               m_maxLines;

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

   void              Background(const int width,const int height)
     {
      string name=m_prefix+"bg";
      if(ObjectFind(0,name)<0)
        {
         if(!ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0))
            return;
         ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
         ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
         ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
         ObjectSetInteger(0,name,OBJPROP_BACK,false);
         ObjectSetInteger(0,name,OBJPROP_BGCOLOR,C'20,24,32');
         ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
         ObjectSetInteger(0,name,OBJPROP_COLOR,C'70,80,100');
        }
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,4);
      ObjectSetInteger(0,name,OBJPROP_YDISTANCE,16);
      ObjectSetInteger(0,name,OBJPROP_XSIZE,width);
      ObjectSetInteger(0,name,OBJPROP_YSIZE,height);
     }

public:
                     CLLBDashboard(void)
     {
      m_enabled=false;
      m_prefix="4LLB_DASH_";
      m_cols=0;
      m_maxLines=0;
     }

   void              Init(const bool enabled,const string prefix)
     {
      m_enabled=enabled;
      m_prefix=prefix;
     }

   void              Deinit(void)
     {
      ObjectsDeleteAll(0,m_prefix);
      ChartRedraw(0);
     }

   //--- header line + one column of lines per symbol
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
      //--- remove labels that are no longer needed
      if(cols!=m_cols || maxLines<m_maxLines)
        {
         ObjectsDeleteAll(0,m_prefix);
         m_cols=cols;
        }
      m_maxLines=maxLines;
      Background(cols*LLB_DASH_COL_W+12,(maxLines+1)*LLB_DASH_LINE_H+14);
      Label(m_prefix+"hdr",12,22,header,clrGold);
      int row[];
      ArrayResize(row,LLB_MAX_SYMBOLS);
      ArrayInitialize(row,0);
      for(int i=0; i<n; i++)
        {
         int c=colOf[i];
         if(c<0 || c>=LLB_MAX_SYMBOLS)
            continue;
         int y=22+LLB_DASH_LINE_H*(row[c]+1);
         Label(m_prefix+"c"+IntegerToString(c)+"_"+IntegerToString(row[c]),12+c*LLB_DASH_COL_W,y,lines[i],colors[i]);
         row[c]++;
        }
      ChartRedraw(0);
     }
  };

#endif
//+------------------------------------------------------------------+
