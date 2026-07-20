enum DashboardContentState {
    case loaded(DashboardViewModel)
    case empty
    case failed(String)
}
