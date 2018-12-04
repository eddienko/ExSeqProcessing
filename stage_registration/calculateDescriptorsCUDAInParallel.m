function success_code = calculateDescriptorsInParallel()

    % get max_jobs
    loadParameters;

    run_num_list = 1:params.NUM_ROUNDS;
    run_num_list_size = length(run_num_list);
    desc_size = regparams.ROWS_DESC * regparams.COLS_DESC;
    max_jobs  = run_num_list_size * desc_size;
    cuda=true;

    arg_list = {};
    postfix_list = {};
    for job_idx = 1:max_jobs
        [run_num, target_idx] = getJobIds(run_num_list, job_idx, desc_size);
        arg_list{end+1} = {run_num, target_idx, target_idx, cuda};
        postfix_list{end+1} = strcat(num2str(run_num), '-', num2str(target_idx));
    end

    [success_code, output] = batch_process('reg1-calcDesc', @calculateDescriptors, run_num_list, arg_list, ...
        postfix_list, params.CALC_DESC_MAX_POOL_SIZE, max_jobs, params.CALC_DESC_MAX_RUN_JOBS, params.WAIT_SEC, params.logDir);
end

