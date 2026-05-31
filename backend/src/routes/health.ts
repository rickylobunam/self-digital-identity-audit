import { FastifyInstance } from 'fastify'

async function healthRoute(fastify: FastifyInstance) {
  fastify.get('/health', async (request, reply) => {
    return { status: 'ok' }
  })
}

export default healthRoute
