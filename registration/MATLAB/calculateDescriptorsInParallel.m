% INPUTS:
% run_num_list is the index list of the experiment for the specified sample
function success_code = calculateDescriptorsInParallel(run_num_list)

    % get max_jobs
    loadExperimentParams;

    run_num_list_size = length(run_num_list);
    desc_size = params.ROWS_DESC * params.COLS_DESC;
    max_jobs  = run_num_list_size * desc_size;

    arg_list = {};
    for job_idx = 1:max_jobs
        [run_num, target_idx] = getJobIds(run_num_list, job_idx, desc_size);
        arg_list{end+1} = {run_num, target_idx, target_idx};
    end

    loadParameters;
    [success_code, output] = batch_process('calcDesc', @calculateDescriptors, run_num_list, arg_list, ...
        params.REG_POOL_SIZE, max_jobs, params.MAX_RUN_JOBS, params.WAIT_SEC, 0, []);

end

