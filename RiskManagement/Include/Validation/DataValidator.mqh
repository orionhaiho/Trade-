//+------------------------------------------------------------------+
//|                                                DataValidator.mqh |
//|                    EA Risk Management - M1 Core & Account Engine |
//|                                                                  |
//| Pure, deterministic validation of an AccountSnapshot:            |
//|   - no terminal / time / account / trading API is called         |
//|   - the input snapshot is never modified, clamped or rounded     |
//|   - every error names the offending property; errors are listed  |
//|     in a fixed order and contain no varying values, so the same  |
//|     input always yields the same result and the same message     |
//|                                                                  |
//| Rules (spec v1.0 + user decision Q-02):                          |
//|   identity       login > 0; server and currency not empty        |
//|                  (whitespace-only counts as empty); company may  |
//|                  be empty                                        |
//|   financials     all 7 values finite (MathIsValidNumber)         |
//|                  margin >= 0                                     |
//|                  balance, equity, free margin, profit, credit:   |
//|                  any sign (Q-02: negative balance/equity/free    |
//|                  margin are legitimate terminal states)          |
//|                  margin level >= 0 when margin > 0 and           |
//|                  equity >= 0 (Q-02: may be negative only when    |
//|                  equity is negative); margin = 0 -> margin level |
//|                  only has to be finite (0 is not an error)       |
//|                  NOT imposed: equity >= balance,                 |
//|                  profit == equity - balance,                     |
//|                  free margin == equity - margin                  |
//|   configuration  leverage > 0; margin mode is one of the         |
//|                  ENUM_ACCOUNT_MARGIN_MODE values; permission     |
//|                  flags are descriptive only (any value is valid) |
//|   times          server_time > 0; collection_time > 0            |
//+------------------------------------------------------------------+
#ifndef RISKMANAGEMENT_VALIDATION_DATAVALIDATOR_MQH
#define RISKMANAGEMENT_VALIDATION_DATAVALIDATOR_MQH

#include "../Models/AccountModel.mqh"

class CDataValidator
  {
private:
   void              AddError(string &errors,const string error) const
     {
      if(StringLen(errors)>0)
         errors=errors+"; ";
      errors=errors+error;
     }

   //--- true when the text is empty or contains only blanks (the value itself is not changed)
   bool              IsBlank(const string value) const
     {
      int length=StringLen(value);
      for(int i=0; i<length; i++)
        {
         ushort character=StringGetCharacter(value,i);
         if(character!=' ' && character!='\t' && character!='\r' && character!='\n')
            return(false);
        }
      return(true);
     }

   bool              CheckFinite(const string property_name,const double value,string &errors) const
     {
      if(MathIsValidNumber(value))
         return(true);
      AddError(errors,property_name+" is not a finite number (NaN or Inf)");
      return(false);
     }

   bool              IsSupportedMarginMode(const long margin_mode) const
     {
      if(margin_mode==(long)ACCOUNT_MARGIN_MODE_RETAIL_NETTING)
         return(true);
      if(margin_mode==(long)ACCOUNT_MARGIN_MODE_EXCHANGE)
         return(true);
      if(margin_mode==(long)ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
         return(true);
      return(false);
     }

   void              CheckIdentity(const AccountSnapshot &snapshot,string &errors) const
     {
      if(snapshot.login<=0)
         AddError(errors,"ACCOUNT_LOGIN must be > 0");
      if(IsBlank(snapshot.server))
         AddError(errors,"ACCOUNT_SERVER must not be empty");
      if(IsBlank(snapshot.currency))
         AddError(errors,"ACCOUNT_CURRENCY must not be empty");
      //--- ACCOUNT_COMPANY is allowed to be empty: not checked
     }

   void              CheckFinancials(const AccountSnapshot &snapshot,string &errors) const
     {
      //--- finiteness of every financial value (NaN / +Inf / -Inf are rejected)
      CheckFinite("ACCOUNT_BALANCE",snapshot.balance,errors);
      bool equity_finite=CheckFinite("ACCOUNT_EQUITY",snapshot.equity,errors);
      CheckFinite("ACCOUNT_PROFIT",snapshot.profit,errors);
      CheckFinite("ACCOUNT_CREDIT",snapshot.credit,errors);
      bool margin_finite=CheckFinite("ACCOUNT_MARGIN",snapshot.margin,errors);
      CheckFinite("ACCOUNT_MARGIN_FREE",snapshot.free_margin,errors);
      bool level_finite=CheckFinite("ACCOUNT_MARGIN_LEVEL",snapshot.margin_level,errors);

      //--- sign rules (applied only to finite values, so one fault is reported once)
      if(margin_finite && snapshot.margin<0.0)
         AddError(errors,"ACCOUNT_MARGIN must be >= 0");
      if(margin_finite && equity_finite && level_finite
         && snapshot.margin>0.0 && snapshot.equity>=0.0 && snapshot.margin_level<0.0)
         AddError(errors,"ACCOUNT_MARGIN_LEVEL must be >= 0 when ACCOUNT_MARGIN > 0 and ACCOUNT_EQUITY >= 0");
     }

   void              CheckConfiguration(const AccountSnapshot &snapshot,string &errors) const
     {
      if(snapshot.leverage<=0)
         AddError(errors,"ACCOUNT_LEVERAGE must be > 0");
      if(!IsSupportedMarginMode(snapshot.margin_mode))
         AddError(errors,"ACCOUNT_MARGIN_MODE is not a supported ENUM_ACCOUNT_MARGIN_MODE value");
      //--- ACCOUNT_TRADE_ALLOWED / ACCOUNT_TRADE_EXPERT are descriptive flags only
     }

   void              CheckTimes(const AccountSnapshot &snapshot,string &errors) const
     {
      if(snapshot.server_time<=0)
         AddError(errors,"SERVER_TIME must be > 0 (TimeTradeServer)");
      if(snapshot.collection_time<=0)
         AddError(errors,"COLLECTION_TIME must be > 0 (TimeLocal)");
     }

public:
                     CDataValidator()
     {
     }

   bool              ValidateAccountIdentity(const AccountSnapshot &snapshot)
     {
      string errors="";
      CheckIdentity(snapshot,errors);
      return(StringLen(errors)==0);
     }

   bool              ValidateAccountFinancials(const AccountSnapshot &snapshot)
     {
      string errors="";
      CheckFinancials(snapshot,errors);
      return(StringLen(errors)==0);
     }

   bool              ValidateAccountConfiguration(const AccountSnapshot &snapshot)
     {
      string errors="";
      CheckConfiguration(snapshot,errors);
      return(StringLen(errors)==0);
     }

   //--- full check in a fixed order: identity, financials, configuration, times
   bool              ValidateSnapshot(const AccountSnapshot &snapshot,string &error_message)
     {
      string errors="";
      CheckIdentity(snapshot,errors);
      CheckFinancials(snapshot,errors);
      CheckConfiguration(snapshot,errors);
      CheckTimes(snapshot,errors);
      error_message=errors;
      return(StringLen(errors)==0);
     }
  };

#endif // RISKMANAGEMENT_VALIDATION_DATAVALIDATOR_MQH
//+------------------------------------------------------------------+
