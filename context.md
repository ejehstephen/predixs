Project: Predix — Nigeria-first prediction markets (Flutter)

Goal:
Create a production-ready mobile UI for a prediction-market MVP. Mobile-first, clean, minimal, trust-focused. Primary colors: deep indigo (#2B2F8A) and accent gold (#F2C94C). Use rounded cards, 12pt/16pt typography for body/title. Provide components and screens with appropriate data bindings to Supabase tables.

Global:
- Font: Inter or Roboto (system fallback).
- SafeArea for all pages.
- Bottom navigation with 4 tabs: Home, Markets, Portfolio, Account.
- Use Riverpod-compatible state patterns (expose provider names in comments).
- Provide reusable components: MarketCard, PriceChip, TradeButton, SmallChart (sparkline), BalanceHeader, EmptyState.

Screens & Components:

1. SplashScreen
- Full screen centered logo, text subtitle "Prediction Markets for Nigeria".
- After 800ms check auth; if logged-in -> navigate to Home; else -> Login.

2. LoginScreen
- Inputs: Email (text), Password (password).
- Buttons: Login (primary), Create Account (link).
- Actions: onLogin -> SupabaseAuth.signIn(email,password) -> on success goto Home.

3. SignUpScreen
- Inputs: Full name, Email, Password, Confirm password.
- Button: Create Account. After create -> send phone verification.

4. PhoneVerificationScreen
- Input: Phone number + Send OTP -> Input OTP -> Verify.
- Actions: On success set user.phone and allow deposits (Tier0).

5. HomeScreen
- Header: BalanceHeader (shows wallet balance from 'wallets' table).
- Quick Actions: Deposit, Withdraw (buttons open respective flows).
- Section: Trending Markets (horizontal list of MarketCard).
- Section: Recent Activity (transactions from 'transactions' table).
- Footer: BottomNavBar.

MarketCard component:
- Props: marketId, title, endTime, yesPrice, noPrice, category, volume.
- Layout: Card with title, subtitle (ends in), two PriceChips (Yes / No), small sparkline chart.
- Tap: navigate to MarketDetailScreen(marketId).

6. MarketsScreen
- Search bar at top.
- Category chips (Sports, Crypto, Nigeria, Pop).
- Vertical list of MarketCard (paginated).
- Filters modal: status (open/closed), date range.

7. MarketDetailScreen
- Title, larger sparkline, ends in X
- Price row: YesPrice (left), NoPrice (right) with percentages.
- Description accordion.
- My Position card: shows user's shares (if any) from 'positions' table.
- Actions: Buy (primary), Sell (secondary). Each open a modal flow.
- Data bindings:
  - Fetch market: from 'markets' table by id.
  - Fetch user position: positions table WHERE user_id & market_id.
  - Price compute: call Edge Function 'get_price' or compute client-side for preview, but final math via edge function on confirm.

8. BuyModal (component)
- Fields: Buy by Amount (₦) OR Buy by Shares (toggle).
- Live preview: Shares to receive, fee estimate, new prices after trade (call endpoint /edge/buy_preview?amount=).
- Confirm button: calls Edge Function 'buy_shares' with user_id, market_id, amount, side='yes' or 'no'.
- On success: show toast, refresh market and portfolio providers.

9. SellModal (component)
- Shows max sellable shares, slider to pick qty, preview receive amount, confirm button -> calls 'sell_shares' edge function.

10. PortfolioScreen
- Header: Total Value, Invested, P/L.
- List: Open Positions (tile with market title, shares, current value, P/L).
- Settled results list below.

11. WalletScreen
- Balance, Deposit button, Withdraw button, Transaction history list.
- Deposit flow: opens DepositScreen.

12. DepositScreen
- Input amount.
- Button: Pay with Paystack -> opens WebView or native checkout.
- After payment, Paystack callback handled by webhookEdgeFunction -> update user wallet.

13. WithdrawScreen
- Input amount, select bank, account number, submit.
- Show note: Withdrawals are manually reviewed initially.
- Submits request to 'transactions' table with type='withdraw_request'.

14. AccountScreen
- Profile info, KYC status, Upgrade KYC (NIN/BVN upload), Support link, Logout.

15. AdminScreens (not in app UI; web admin idea)
- MarketCreateScreen (title, desc, category, end_time, b_param, initial_liquidity)
- MarketResolve screen with evidence upload and resolve button.

Animations & Microcopy:
- Use subtle elevation on cards (shadow 4).
- Buttons: primary rounded 8px.
- Success messages on deposits/trades.
- Error states: network or insufficient balance flows.

Data mapping (bind component -> Supabase table):
- BalanceHeader -> wallets.balance (aggregate from 'wallets' or 'transactions')
- MarketCard -> markets table fields: id,title, end_time, yes_price,no_price
- Buy/Sell -> call edge functions to mutate trades & positions
- Transaction history -> transactions table rows

Accessibility:
- Provide readable font sizes, contrast ratios, and proper touch targets (minimum 48x48).
- Localize currency to NGN with symbol "₦".

Deliverables:
- Provide exported Flutter widget files for each major screen and re-usable components.
- Include provider names in comments, e.g., // Provider: marketListProvider
- Include simple route map in comments at top of main.dart snippet.

End of prompt.
