using Microsoft.Xrm.Sdk;
using Microsoft.Xrm.Sdk.Query;

namespace Pasqui.Innova.Plugins.Tests.Fakes;

/// <summary>
/// Fake IOrganizationService: solo implementa los metodos que usan los plug-ins de INNOVA.
/// Reemplaza a NSubstitute/Castle (que no puede proxyar IOrganizationService por custom attrs del CrmSdk).
/// </summary>
internal sealed class FakeOrganizationService : IOrganizationService
{
    public Func<string, Guid, ColumnSet, Entity>? RetrieveHandler { get; set; }
    public Func<QueryBase, EntityCollection>? RetrieveMultipleHandler { get; set; }

    // Counters para asserts
    public int RetrieveCallCount { get; private set; }
    public int RetrieveMultipleCallCount { get; private set; }
    public QueryBase? LastQuery { get; private set; }

    public Entity Retrieve(string entityName, Guid id, ColumnSet columnSet)
    {
        RetrieveCallCount++;
        if (RetrieveHandler == null)
            throw new InvalidOperationException("RetrieveHandler no configurado en el test");
        return RetrieveHandler(entityName, id, columnSet);
    }

    public EntityCollection RetrieveMultiple(QueryBase query)
    {
        RetrieveMultipleCallCount++;
        LastQuery = query;
        if (RetrieveMultipleHandler == null)
            throw new InvalidOperationException("RetrieveMultipleHandler no configurado en el test");
        return RetrieveMultipleHandler(query);
    }

    // Metodos no usados por el plug-in -> throw para que falle ruidoso si alguien los llama por error
    public Guid Create(Entity entity) => throw new NotImplementedException("Fake no implementa Create");
    public void Update(Entity entity) => throw new NotImplementedException("Fake no implementa Update");
    public void Delete(string entityName, Guid id) => throw new NotImplementedException("Fake no implementa Delete");
    public OrganizationResponse Execute(OrganizationRequest request) => throw new NotImplementedException("Fake no implementa Execute");
    public void Associate(string entityName, Guid entityId, Relationship relationship, EntityReferenceCollection relatedEntities) => throw new NotImplementedException();
    public void Disassociate(string entityName, Guid entityId, Relationship relationship, EntityReferenceCollection relatedEntities) => throw new NotImplementedException();
}
