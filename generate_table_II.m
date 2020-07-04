% This script performs the calculations described in Section V of the paper
% Economies of Scope for Electricity Storage and Variable Renewables 
% by Goncalo Terca and David Wozabal
%
clear; clc;

% loading data
load 'data/windPowerFeedIn_2019.mat';           % Wind forecast and actual production
load 'data/REBAP_2019.mat';                     % REBAP prices
load 'data/DA_2019.mat';                        % DA prices
load 'data/ID_1_2019.mat';                      % ID_1 prices
load 'data/ID_2019.mat';                        % ID prices
load 'data/vol_1s_res_2019.mat';                % second per second call offs in the balancing market
load 'data/bid_data.mat';                       % data on balancing market auctions (prices & quantities)

% execute clairvoyant bidding strategy on spot markets and generate left
% panel of Table II in the paper
fprintf('Generating results for spot upper bound ... ');
ub_spot_bidding;
fprintf('finished.\n');

% execute lower bound on secondary control reserve bidding and generate
% right panel of Table II in the paper
fprintf('Generating results for reserve lower bound ... ');
lb_secondary_control_reserve;
fprintf('finished.\n\n');

fprintf('------------------------------------------------------\n');
fprintf('---------------------- TABLE II ----------------------\n');
fprintf('------------------------------------------------------\n');
fprintf('   Spot Upper Bound        |    Reserve Lower Bound   \n');
fprintf('   ----------------        |    -------------------   \n');
fprintf('Day-ahead trading: %.0f    | Positive Capacity: %.0f\n', DA_profits, profit_pos_cap);
fprintf('Intraday trading : %.0f   | Negative Capacity: %.0f\n', ID_profits, profit_neg_cap);
fprintf('Avoided balancing: %.0f    | Positive Power   : %.0f\n', -balancing_cost, profit_pos_pow);
fprintf('                           | Negative Power   : %.0f\n', profit_neg_pow);
fprintf('                           | ID Trading       : %.0f\n', profits_ID);
fprintf('                           |                        \n');
fprintf('Total            : %.0f   | Total            : %.0f\n', DA_profits+ID_profits-balancing_cost, profit_pos_cap+profit_neg_cap+profit_pos_pow+profit_neg_pow+profits_ID);
fprintf('------------------------------------------------------\n\n');
