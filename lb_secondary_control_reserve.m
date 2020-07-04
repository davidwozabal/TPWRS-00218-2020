% This script calculates the revenies for the lower bound bidding on the 
% secondary control reserve (SCR). There are six markets for upregulation 
% and six markets for downregulation for every day, each covering 4 hours.

% parameters of the strategy (quantiles of yesterday's auction to determine
% bid prices for power and capacity)
q_cap_pos = 0.5; q_cap_neg = 0.5;
q_pow_pos = 0.01; q_pow_neg = 0.99;
bid_quant_pos = 1; bid_quant_neg = 1;

initial_storage = 0.5; % initial storage level

% loop through markets determine whether bids are accepted and calculate
% power flows on a 5-minute basis. start with market 7, which is the first
% market on the 01.08.2018. The first six markets from the 31.07.2018 are 
% stored in bids_data in order to be able to compute bid prices for the
% strategy
profit_pos_cap = 0; profit_neg_cap = 0;
profit_pos_pow = 0; profit_neg_pow = 0;
level_change = zeros(365*24*12, 1);
accepted_pos_total = 0; accepted_neg_total = 0;
called_off_pos = 0; called_off_neg = 0;

for m = 7:length(bids_pos)
    % get capacity price bids for the market from quantiles of accepted
    % bids from the same market on the day before
    bid_cap_pos = quantile_nu(bids_pos(m-6).cap_price, bids_pos(m-6).accepted / sum(bids_pos(m-6).accepted), q_cap_pos);
    bid_cap_neg = quantile_nu(bids_neg(m-6).cap_price, bids_neg(m-6).accepted / sum(bids_neg(m-6).accepted), q_cap_neg);
    
    % get energy price bids for the market from quantiles of accepted
    % bids from the same market on the day before
    bid_pow_pos = quantile_nu(bids_pos(m-6).energy_price, bids_pos(m-6).accepted / sum(bids_pos(m-6).accepted), q_pow_pos);
    bid_pow_neg = quantile_nu(bids_neg(m-6).energy_price, bids_neg(m-6).accepted / sum(bids_neg(m-6).accepted), q_pow_neg);
   
    % calculate market size
    market_size_neg = sum(bids_neg(m).accepted);
    market_size_pos = sum(bids_pos(m).accepted);
    
    % calculate how much of the capacity bids are accepted
    I = find(bids_pos(m).cap_price >= bid_cap_pos, 1);
    if isempty(I)
        accepted_pos = 0;
    else
        accepted_pos = min(max(market_size_pos - sum(bids_pos(m).quant(1:I)), 0), bid_quant_pos);
    end
    accepted_pos_total = accepted_pos_total + accepted_pos;
    
    I = find(bids_neg(m).cap_price >= bid_cap_neg, 1);
    if isempty(I)
        accepted_neg = 0;
    else
        accepted_neg = min(max(market_size_neg - sum(bids_neg(m).quant(1:I)), 0), bid_quant_neg);
    end
    accepted_neg_total = accepted_neg_total + accepted_neg;
    
    % if capacity bid in market for positive control reserve is accepted
    % calculate the revenue from both power and energy and the actual flows
    % in a 15-minute resolution
    if accepted_pos > 0
        % profits from selling capacity
        profit_pos_cap = profit_pos_cap + accepted_pos * bid_cap_pos;
        
        % calculate threshold for power call-off
        [sorted_price, I] = sort(bids_pos(m).energy_price, 'ascend');
        sorted_quant = bids_pos(m).quant(I);
        I = find(sorted_price >  bid_pow_pos, 1);
        if isempty(I)
            threshold = sum(sorted_quant);
        else
            threshold = sum(sorted_quant(1:I-1));
        end
            
        % calculate call-offs and revenues from call-offs
        I = (m-7)*3600*4+1:(m-6)*3600*4;
        % call-offs for the whole market
        call_offs = vol_1s_res(I); 
        % call-offs for the storage operator
        call_offs = min( max(call_offs - threshold, 0), 1); 
        profit_pos_pow = profit_pos_pow + sum(call_offs) / 3600 * bid_pow_pos;
        
        % calculate impact of call-offs on storage level (in MWh) in 
        % 5-minute intervals
        call_offs_5min = mean(reshape(call_offs, 300, 4*12))' / 12;
        level_change((m-7)*4*12+1: (m-6)*4*12) = level_change((m-7)*4*12+1: (m-6)*4*12) - call_offs_5min;
        
        called_off_pos = called_off_pos + sum(call_offs)/3600;
    end
    
    % if capacity bid in market for negative control reserve is accepted
    % calculate the revenue from power and the cost for energy and the 
    % actual flows in a 15-minute resolution
    if accepted_neg > 0
        % profits from selling capacity
        profit_neg_cap = profit_neg_cap + accepted_neg * bid_cap_neg;
        
        % Calculate threshold for power call-off
        % INTERPRETATION OF PRICES: The price that the storage pays for receiving energy
        % If a price is negative then the storage receives a payment for 
        % taking the power. The tries to achieve a price as high as
        % possible for the negative balancing power
        [sorted_price, I] = sort(bids_neg(m).energy_price, 'descend');
        sorted_quant = bids_neg(m).quant(I);
        I = find(sorted_price <  bid_pow_neg, 1);
        if isempty(I)
            threshold = sum(sorted_quant);
        else
            threshold = sum(sorted_quant(1:I-1));
        end
            
        % calculate call-offs and revenues from call-offs
        I = (m-7)*3600*4+1:(m-6)*3600*4; % index of relevant second for the market
        % call-offs for the whole market
        call_offs = vol_1s_res(I); 
        % call-offs for the storage operator (call-offs happen for negative
        % values of vol_1s_res)
        call_offs = min( max(-call_offs - threshold, 0), 1); 
        profit_neg_pow = profit_neg_pow - sum(call_offs) / 3600 * bid_pow_neg;
        
        % calculate impact of call-offs on storage level ((in MWh) in 
        % 5-minute intervals
        call_offs_5min = mean(reshape(call_offs, 300, 4*12))' / 12;
        level_change((m-7)*4*12+1: (m-6)*4*12) = level_change((m-7)*4*12+1: (m-6)*4*12) + call_offs_5min;
        
        called_off_neg = called_off_neg + sum(call_offs)/3600;
    end
end

% Balancing on the intraday market
% RULE: Five minutes before the end of every 15-minute interval place an
% order for delivery in the next 15 minute interval. The order has to be
% such that call-offs can not bring the storage level to 0 or above 1 in
% the next 20 minutes, given residual order for the 5 minutes of the
% current quarter hour.
%
% Hence, given a storage level s at the time of computation and a order 
% of size x on the intraday market, which will be delivered in the last 5 
% minutes of the current 15-minute interval, we determine the order size as
%
% q = min((s - x/3) - 1/3 * bid_quant_pos, 0) + max((s - x/3) + 1/3 * bid_quant_neg - 1, 0)
%
% where (s-x/3) is the storage level in 5 minutes if there are no further 
% call-offs. The first term takes care of the case of running out of energy
% due to call-offs of positive energy for 1/3 of an hour (20 minutes) while
% the second term takes care of the situation of overflow. 

% loop over all time periods 5 minutes before the end of a 15-minute
% interval
index = 2; % first order is placed after 2 5-minute intervals passed
last_bid = 0; level = initial_storage;
storageLevel = zeros(8760*4+1, 1); intraday_bids = zeros(8670 * 4, 1);
storageLevel(1) = initial_storage;
profits_ID = 0;
for q = 1:8760*4
    % storage level at the time of decision about next bid (s)
    level_at_decision = level - last_bid * 2/3 + sum(level_change((q-1)*3+1:(q-1)*3+2)); 
    
    % bid (in MWh)
    ID_q = min((level_at_decision - last_bid/3) - 1/3 * bid_quant_pos, 0) ...
        + max((level_at_decision - last_bid/3) + 1/3 * bid_quant_neg - 1, 0);
    intraday_bids(q) = ID_q;
    
    % if prices are low in the next 15 minutes try to buy a little more if
    % possible
    if q > 96 && Price_ID_1qh(q) < quantile(Price_ID_1qh(q-96:q-1), 0.5) && ID_q <= 0 && (level_at_decision - last_bid/3) < 0.5
        ID_q = -min(0.25, 0.75 - (level_at_decision - last_bid/3));
    end
    
    % if prices are high in the next 15 minutes try to sell a little more if
    % possible
    if q > 96 && Price_ID_1qh(q) > quantile(Price_ID_1qh(q-96:q-1), 0.5) && ID_q >= 0 && (level_at_decision - last_bid/3) > 0.5
        ID_q = min(0.25, (level_at_decision - last_bid/3) - 0.25);
    end
    
    % profits/cost from intraday trading
    profits_ID = profits_ID + ID_q * Price_ID_1qh(q);
    
    % new level at the end of the period
    level = level_at_decision - last_bid/3 + level_change((q-1)*3+3);
    storageLevel(q+1) = level;
    
    last_bid = ID_q;    
end