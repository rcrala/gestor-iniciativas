using System;
using Microsoft.Xrm.Sdk;

namespace Pasqui.Innova.Plugins.Common
{
    public class LocalPluginContext
    {
        public IPluginExecutionContext PluginExecutionContext { get; }
        public IOrganizationService OrgService { get; }
        public ITracingService TracingService { get; }

        public LocalPluginContext(IServiceProvider serviceProvider)
        {
            if (serviceProvider == null) throw new ArgumentNullException(nameof(serviceProvider));

            TracingService = (ITracingService)serviceProvider.GetService(typeof(ITracingService));
            PluginExecutionContext = (IPluginExecutionContext)serviceProvider.GetService(typeof(IPluginExecutionContext));
            var factory = (IOrganizationServiceFactory)serviceProvider.GetService(typeof(IOrganizationServiceFactory));
            OrgService = factory.CreateOrganizationService(PluginExecutionContext.UserId);
        }
    }

    public abstract class PluginBase : IPlugin
    {
        public void Execute(IServiceProvider serviceProvider)
        {
            if (serviceProvider == null) throw new ArgumentNullException(nameof(serviceProvider));
            var ctx = new LocalPluginContext(serviceProvider);

            try
            {
                ctx.TracingService.Trace("{0}: enter Execute", GetType().Name);
                ExecuteInternal(ctx);
                ctx.TracingService.Trace("{0}: exit Execute (ok)", GetType().Name);
            }
            catch (InvalidPluginExecutionException)
            {
                throw;
            }
            catch (Exception ex)
            {
                ctx.TracingService.Trace("{0}: exception {1}", GetType().Name, ex);
                throw new InvalidPluginExecutionException(
                    string.Format("Error en {0}: {1}", GetType().Name, ex.Message), ex);
            }
        }

        protected abstract void ExecuteInternal(LocalPluginContext context);
    }
}
