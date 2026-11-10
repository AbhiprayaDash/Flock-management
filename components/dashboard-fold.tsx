import {ReactNode} from 'react';
export function DashboardFold({title,hint,children,id}:{id?:string;title:string;hint:string;children:ReactNode}){return <details id={id} className="dashboard-fold"><summary><span><b>{title}</b><small>{hint}</small></span><span className="fold-action">Open <span aria-hidden="true">⌄</span></span></summary><div className="fold-content">{children}</div></details>}
