% This script calculates the upper bound on spot bidding with perfect foresight
% as well as the imbalance cost of the wind farm as described in the paper
% and generates the left panel of Table II as an output on the command line

% parameters
total_Wind_Capacity_2018 = 27422; % (MW) source:https://www.windguard.de/veroeffentlichungen.html (WindGuard)
Wind_Power = 1; % (MW)
Wind_forecast = Wind_forecast/total_Wind_Capacity_2018; % Normalization by capacity factor
Wind_observed = Wind_observed/total_Wind_Capacity_2018; % Normalization by capacity factor
storage_Capacity_Max = 1; %(MWh) 
storage_Power_Output_Max = 2; %(MW)
storage_Power_Input_Max = 2; %(MW)
initialStorage = storage_Capacity_Max / 2; % initial state of charge and storage level

% imbalance result scaled by the factor of 3
balancing_cost = 3/4*Wind_Power*(Wind_observed-Wind_forecast)'*REBAP;

% optimal bidding with storage unit on DA + ID
M = 8760 * 4; % number of quarter hours in 365 days
storage_level = sdpvar(M,1);	% storage level				(in MWh)
withdraw = sdpvar(M,1); 		% withdrawal from storage 	(in MW)
inject = sdpvar(M,1);			% injection to storage		(in MW)

% trading decisions in power (MW), positive values are sales
trading_DA = sdpvar(M, 1); trading_ID = sdpvar(M, 1);

% Box contraints for variables
Constraints = [inject >= 0, inject <= storage_Power_Input_Max, withdraw >= 0, withdraw <= storage_Power_Output_Max, storage_level >= 0, storage_level <= storage_Capacity_Max];

% connection between bids and physical operation
Constraints = [Constraints, trading_DA + trading_ID == withdraw - inject];

% Balance continuity constraints
Constraints = [Constraints, storage_level(1) == initialStorage + (inject(1) - withdraw(1)) / 4];
Constraints = [Constraints, storage_level(2:end) == storage_level(1:end-1) + (inject(2:end) - withdraw(2:end)) / 4];

% Constrain trading decisions to power of storage
Constraints = [Constraints, trading_DA <= storage_Power_Output_Max, trading_ID <= storage_Power_Output_Max];
Constraints = [Constraints, trading_DA >= -storage_Power_Input_Max, trading_ID >= -storage_Power_Input_Max];

% Back-to-back constraints DA market: the DA schedule has to be physically implementable without ID trades
Constraints = [Constraints, 0 <= initialStorage + cumsum(trading_DA(1:96)) / 4 <= storage_Capacity_Max];
for d = 2:365
    Constraints = [Constraints, 0 <= storage_level( (d-1) * 96) + cumsum(trading_DA((d-1)*96+1:d*96)) / 4 <= storage_Capacity_Max];
end

% Constraint making sure that DA bids remain fixed within one hour
for i = 2:4
    Constraints = [Constraints, trading_DA(i:4:M) == trading_DA(1:4:M)];
end

% objective function: trading in power (divide by 4 to convert to MWh)
obj = sum(trading_DA .* repelem(Price_DA, 4) + trading_ID .* Price_IDqh) / 4;

% solve problem
ops = sdpsettings('verbose', 0);
r = optimize(Constraints, -obj, ops);

DA_profits = double(sum(trading_DA .* repelem(Price_DA, 4)) / 4);
ID_profits = double(sum(trading_ID .* Price_IDqh) / 4);


