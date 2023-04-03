defmodule TS.Type.ReportType do
  use EctoEnum.Postgres,
    type: :report_type,
    enums: [:X_REPORT, :Z_REPORT]

  @type type :: :X_REPORT | :Z_REPORT
end
