using GLPK
using HydroPowerModels

########################################
#       Load Case
########################################
testcases_dir = joinpath(dirname(dirname(dirname(@__FILE__))), "testcases")
data = HydroPowerModels.parse_folder(joinpath(testcases_dir,"case3deterministic_nowater"))

########################################
#       Set Parameters
########################################
# model_constructor_grid may be for example: ACPPowerModel or DCPPowerModel
# optimizer may be for example: IpoptSolver(tol=1e-6) or GLPK.Optimizer
params = create_param(  stages = 12, 
                        model_constructor_grid  = DCPPowerModel,
                        post_method             = PowerModels.post_opf,
                        optimizer               = with_optimizer(GLPK.Optimizer));

########################################
#       Build Model
########################################
m = hydrothermaloperation(data, params)

########################################
#       Solve
########################################
HydroPowerModels.train(m;iteration_limit = 60,stopping_rules= [SDDP.Statistical(num_replications = 20,iteration_period=20)]);

########################################
#       Simulation
########################################
results = HydroPowerModels.simulate(m, 1);

########################################
#       Test
########################################
# objective
@test isapprox(sum(s[:stage_objective] for s in results[:simulations][1]),42006.85, atol=1e-2)

# solution
@test results[:simulations][1][1][:powersystem]["solution"]["bus"]["3"]["deficit"] == 0
@test isapprox(results[:simulations][1][1][:powersystem]["solution"]["gen"]["2"]["pg"],0.18, atol=1e-2)
@test isapprox(results[:simulations][1][1][:powersystem]["solution"]["gen"]["3"]["pg"],0, atol=1e-2)
@test isapprox(results[:simulations][1][1][:powersystem]["solution"]["gen"]["1"]["pg"],0.81, atol=1e-2)