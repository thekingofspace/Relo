export type project_info = {
    project_name:string,
    default_port:number,
    heartbeat_interval:number,
    log_actions:{
        error:boolean,
        warn:boolean,
        connection:boolean
    }
}

export type staged<i> = {
    op:number,
    d:i
}

return true